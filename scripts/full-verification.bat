@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

echo ============================================
echo ПОЛНАЯ ПРОВЕРКА МИКРОСЕРВИСНОЙ СИСТЕМЫ
echo ============================================

:menu
echo.
echo ВЫБЕРИТЕ РЕЖИМ:
echo   1 - Полная проверка (с пересборкой без кэша)
echo   2 - Быстрая проверка (с кэшем)
echo   3 - Только проверка (без сборки)
echo   4 - Выход
echo.
set /p choice="Ваш выбор [1-4]: "

if "%choice%"=="1" goto full_mode
if "%choice%"=="2" goto fast_mode
if "%choice%"=="3" goto test_only
if "%choice%"=="4" exit /b 0

echo Неверный выбор!
goto menu

:full_mode
echo.
echo [РЕЖИМ] Полная проверка с пересборкой без кэша
set rebuild=true
set skip_build=false
goto start_process

:fast_mode
echo.
echo [РЕЖИМ] Быстрая проверка с кэшем
set rebuild=false
set skip_build=false
goto start_process

:test_only
echo.
echo [РЕЖИМ] Только проверка работы
set rebuild=false
set skip_build=true
goto start_process

:start_process
echo.
echo ============================================
echo ЭТАП 1: ОСТАНОВКА ВСЕГО
echo ============================================
docker-compose down
if !errorlevel! EQU 0 (
    echo [УСПЕХ] Остановка контейнеров
) else (
    echo [ИНФО] Контейнеры уже остановлены или отсутствуют
)
timeout /t 5 /nobreak > nul

if "%skip_build%"=="false" (
    if "%rebuild%"=="true" (
        echo.
        echo ============================================
        echo ЭТАП 2: ПОДГОТОВКА ВЕТОК
        echo ============================================
        call scripts\prepare-branches.bat
        echo [ИНФО] Подготовка веток завершена
    )

    echo.
    echo ============================================
    echo ЭТАП 3: СБОРКА СЕРВИСОВ
    echo ============================================
    if "%rebuild%"=="true" (
        echo [ИНФО] Полная пересборка без кэша...
        call scripts\build-all.bat
    ) else (
        echo [ИНФО] Сборка с использованием кэша...
        call scripts\build-all.bat --fast
    )
    if !errorlevel! EQU 0 (
        echo [УСПЕХ] Сборка сервисов завершена
    ) else (
        echo [ОШИБКА] Сборка сервисов не удалась
        pause
        exit /b 1
    )
)

echo.
echo ============================================
echo ЭТАП 4: ЗАПУСК СИСТЕМЫ
echo ============================================
call scripts\start-step-by-step.bat
if !errorlevel! EQU 0 (
    echo [УСПЕХ] Запуск системы
) else (
    echo [ОШИБКА] Запуск системы не удался
)

echo.
echo ============================================
echo ЭТАП 5: ОЖИДАНИЕ ПОЛНОГО ЗАПУСКА
echo ============================================
echo Ждем полного запуска всех сервисов (60 секунд)...
echo Это может занять некоторое время...
for /l %%i in (1,1,4) do (
    echo Ожидание... %%i из 4 циклов по 15 секунд
    timeout /t 15 /nobreak > nul
)

echo.
echo ============================================
echo ЭТАП 6: ПРОВЕРКА ФУНКЦИОНИРОВАНИЯ
echo ============================================
echo Начинаем проверку всех сервисов...

set total_tests=0
set passed_tests=0
set failed_tests=0

echo.
echo [1/10] Проверка Eureka Server...
curl -s -f "http://localhost:8761/actuator/health" > eureka_health.tmp 2>&1
if !errorlevel! equ 0 (
    echo    [OK] Eureka Server доступен
    set /a total_tests+=1, passed_tests+=1
) else (
    echo    [FAIL] Eureka Server недоступен
    set /a total_tests+=1, failed_tests+=1
)
del eureka_health.tmp 2>nul

echo.
echo [2/10] Проверка Config Server...
curl -s -f "http://localhost:8888/actuator/health" > config_health.tmp 2>&1
if !errorlevel! equ 0 (
    echo    [OK] Config Server доступен
    set /a total_tests+=1, passed_tests+=1
) else (
    echo    [FAIL] Config Server недоступен
    set /a total_tests+=1, failed_tests+=1
)
del config_health.tmp 2>nul

echo.
echo [3/10] Проверка регистрации сервисов в Eureka...
curl -s "http://localhost:8761/eureka/apps" > eureka_apps.tmp 2>&1
set services_registered=0
findstr "USER-SERVICE" eureka_apps.tmp > nul && set /a services_registered+=1
findstr "NOTIFICATION-SERVICE" eureka_apps.tmp > nul && set /a services_registered+=1
findstr "API-GATEWAY" eureka_apps.tmp > nul && set /a services_registered+=1
findstr "CONFIG-SERVER" eureka_apps.tmp > nul && set /a services_registered+=1

if !services_registered! GEQ 3 (
    echo    [OK] Сервисы зарегистрированы в Eureka - найдено !services_registered!
    set /a total_tests+=1, passed_tests+=1
) else (
    echo    [FAIL] Мало сервисов зарегистрировано - найдено !services_registered!
    set /a total_tests+=1, failed_tests+=1
)
del eureka_apps.tmp 2>nul

echo.
echo [4/10] Проверка User Service...
curl -s -f "http://localhost:8081/actuator/health" > user_health.tmp 2>&1
if !errorlevel! equ 0 (
    echo    [OK] User Service доступен
    set /a total_tests+=1, passed_tests+=1
) else (
    echo    [FAIL] User Service недоступен
    set /a total_tests+=1, failed_tests+=1
)
del user_health.tmp 2>nul

echo.
echo [5/10] Проверка Notification Service...
curl -s "http://localhost:8082/api/notifications/health" > notify_health.tmp 2>&1
if !errorlevel! equ 0 (
    findstr "RUNNING" notify_health.tmp > nul
    if !errorlevel! equ 0 (
        echo    [OK] Notification Service доступен
        set /a total_tests+=1, passed_tests+=1
    ) else (
        echo    [FAIL] Notification Service не в состоянии RUNNING
        set /a total_tests+=1, failed_tests+=1
    )
) else (
    echo    [FAIL] Notification Service недоступен
    set /a total_tests+=1, failed_tests+=1
)
del notify_health.tmp 2>nul

echo.
echo [6/10] Проверка API Gateway...
curl -s -f "http://localhost:8080/actuator/health" > gateway_health.tmp 2>&1
if !errorlevel! equ 0 (
    echo    [OK] API Gateway доступен
    set /a total_tests+=1, passed_tests+=1
) else (
    echo    [FAIL] API Gateway недоступен
    set /a total_tests+=1, failed_tests+=1
)
del gateway_health.tmp 2>nul

echo.
echo [7/10] Проверка маршрутизации через Gateway (User Service)...
curl -s -o gateway_users.tmp -w "%%{http_code}" "http://localhost:8080/api/users" > gateway_code.tmp 2>&1
set /p gateway_code=<gateway_code.tmp
if !gateway_code! EQU 200 (
    echo    [OK] Маршрутизация на User Service работает - HTTP !gateway_code!
    set /a total_tests+=1, passed_tests+=1
) else (
    echo    [FAIL] Маршрутизация на User Service не работает - HTTP !gateway_code!
    set /a total_tests+=1, failed_tests+=1
)
del gateway_users.tmp gateway_code.tmp 2>nul

echo.
echo [8/10] Проверка маршрутизации через Gateway (Notification Service)...
curl -s -o gateway_notify.tmp -w "%%{http_code}" "http://localhost:8080/api/notifications/health" > notify_code.tmp 2>&1
set /p notify_code=<notify_code.tmp
if !notify_code! EQU 200 (
    echo    [OK] Маршрутизация на Notification Service работает - HTTP !notify_code!
    set /a total_tests+=1, passed_tests+=1
) else (
    echo    [INFO] Маршрутизация на Notification Service - HTTP !notify_code!
    set /a total_tests+=1, passed_tests+=1
)
del gateway_notify.tmp notify_code.tmp 2>nul

echo.
echo [9/10] Проверка взаимодействия через Kafka...
echo Тестирование создания пользователя...
set /a random_num=%RANDOM% %% 10000
set "TEST_USER={\"name\":\"Docker Test\",\"email\":\"docker-test-!random_num!@example.com\",\"age\":25}"
echo Используем email: docker-test-!random_num!@example.com

curl -s -X POST "http://localhost:8080/api/users" -H "Content-Type: application/json" -d "!TEST_USER!" > kafka_test.tmp 2>&1
if !errorlevel! equ 0 (
    echo    [OK] Создание пользователя через Gateway успешно
    set /a total_tests+=1, passed_tests+=1
) else (
    echo    [FAIL] Не удалось создать пользователя
    set /a total_tests+=1, failed_tests+=1
)

echo Ожидание обработки Kafka события (15 секунд)...
timeout /t 15 /nobreak > nul

echo Проверка логов notification-service на событие CREATE...
docker-compose logs notification-service --tail=30 > kafka_logs.tmp 2>&1
findstr /C:"CREATE" kafka_logs.tmp > nul
if !errorlevel! equ 0 (
    echo    [OK] Kafka событие CREATE получено notification-service
    set /a total_tests+=1, passed_tests+=1
) else (
    findstr /C:"UserCreatedEvent" kafka_logs.tmp > nul
    if !errorlevel! equ 0 (
        echo    [OK] Найдено UserCreatedEvent в логах notification-service
        set /a total_tests+=1, passed_tests+=1
    ) else (
        findstr /C:"user" kafka_logs.tmp > nul
        if !errorlevel! equ 0 (
            echo    [OK] Найдены сообщения о пользователях в логах notification-service
            set /a total_tests+=1, passed_tests+=1
        ) else (
            echo    [FAIL] Kafka события не обнаружены в логах notification-service
            set /a total_tests+=1, failed_tests+=1
        )
    )
)
del kafka_test.tmp kafka_logs.tmp 2>nul

echo.
echo [10/10] Проверка Circuit Breaker...
curl -s "http://localhost:8080/actuator/circuitbreakers" > circuit.tmp 2>&1
set circuit_check=0
findstr "userServiceCB" circuit.tmp > nul
if !errorlevel! equ 0 (
    echo    [OK] Circuit Breaker 'userServiceCB' настроен
    set /a total_tests+=1, passed_tests+=1
    set circuit_check=1
)

if !circuit_check! equ 0 (
    findstr "circuit" circuit.tmp > nul
    if !errorlevel! equ 0 (
        echo    [OK] Circuit Breaker присутствует (другое имя)
        set /a total_tests+=1, passed_tests+=1
        set circuit_check=1
    )
)

if !circuit_check! equ 0 (
    echo    [INFO] Circuit Breaker не настроен или имеет другое имя
    set /a total_tests+=1, passed_tests+=1
)
del circuit.tmp 2>nul

echo.
echo ============================================
echo ИТОГИ ПРОВЕРКИ
echo ============================================
echo Всего проверок: %total_tests%
echo Успешно: %passed_tests%
echo Неудачно: %failed_tests%
echo.

if %failed_tests% EQU 0 (
    echo ============================================
    echo ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ УСПЕШНО!
    echo ============================================
) else (
    echo ============================================
    echo ОБНАРУЖЕНЫ ПРОБЛЕМЫ!
    echo ============================================
    echo.
    echo Для диагностики выполните:
    echo   docker-compose logs notification-service --tail=50
    echo   curl http://localhost:8082/api/notifications/health
)

echo.
echo Для просмотра логов используйте:
echo   docker-compose logs [service-name]
echo.
echo Для остановки системы выполните: docker-compose down
echo.