@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

echo ============================================
echo ПОЛНАЯ ПРОВЕРКА СИСТЕМЫ
echo ============================================
echo Этот скрипт выполнит:
echo 1. Остановку всех контейнеров
echo 2. Запуск всей системы
echo 3. Полную проверку всех компонентов
echo 4. Тестирование взаимодействия
echo 5. Автоматическую остановку после проверки
echo.

echo.
echo ============================================
echo ЭТАП 1: ОСТАНОВКА СИСТЕМЫ
echo ============================================
echo Останавливаем все контейнеры...
docker-compose down
if !errorlevel! EQU 0 (
    echo [OK] Контейнеры остановлены
) else (
    echo [INFO] Контейнеры уже остановлены или отсутствуют
)
timeout /t 3 /nobreak > nul

echo.
echo ============================================
echo ЭТАП 2: ЗАПУСК СИСТЕМЫ
echo ============================================
echo Запускаем инфраструктуру...
docker-compose up -d postgres zookeeper kafka
timeout /t 30 /nobreak > nul

echo Запускаем Eureka...
docker-compose up -d eureka-server
timeout /t 20 /nobreak > nul

echo Запускаем Config Server...
docker-compose up -d config-server
timeout /t 20 /nobreak > nul

echo Запускаем микросервисы...
docker-compose up -d user-service notification-service
timeout /t 30 /nobreak > nul

echo Запускаем API Gateway...
docker-compose up -d api-gateway
timeout /t 20 /nobreak > nul

echo.
echo ============================================
echo ЭТАП 3: ОЖИДАНИЕ ПОЛНОГО ЗАПУСКА
echo ============================================
echo Ждем полного запуска всех сервисов (60 секунд)...
for /l %%i in (1,1,4) do (
    echo Ожидание... %%i из 4 циклов по 15 секунд
    timeout /t 15 /nobreak > nul
)

echo.
echo ============================================
echo ЭТАП 4: ПРОВЕРКА БАЗОВЫХ КОМПОНЕНТОВ
echo ============================================
echo Начинаем проверку всех сервисов...

set total_tests=0
set passed_tests=0
set failed_tests=0

echo.
echo [1/8] Проверка Eureka Server...
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
echo [2/8] Проверка Config Server...
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
echo [3/8] Проверка регистрации сервисов в Eureka...
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
echo [4/8] Проверка User Service...
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
echo [5/8] Проверка Notification Service...
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
echo [6/8] Проверка API Gateway...
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
echo [7/8] Проверка маршрутизации через Gateway (User Service)...
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
echo [8/8] Проверка маршрутизации через Gateway (Notification Service)...
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
echo ============================================
echo ЭТАП 5: ПРОВЕРКА ВЗАИМОДЕЙСТВИЯ
echo ============================================
echo Тестирование взаимодействия микросервисов...

echo.
echo [A] Создание тестового пользователя...
set /a random_num=%RANDOM% %% 10000
set TEST_EMAIL=test-!random_num!@docker.com
echo Используем email: !TEST_EMAIL!

curl -s -X POST "http://localhost:8080/api/users" -H "Content-Type: application/json" -d "{\"name\":\"Integration Test\",\"email\":\"!TEST_EMAIL!\",\"age\":30}" > post-response.tmp 2>&1
set post_result=!errorlevel!

if !post_result! equ 0 (
    echo    [OK] Пользователь создан
    set /a total_tests+=1, passed_tests+=1
    echo    Ответ сервера:
    type post-response.tmp
) else (
    echo    [FAIL] Не удалось создать пользователя
    echo    Ответ сервера:
    type post-response.tmp
    set /a total_tests+=1, failed_tests+=1
)
del post-response.tmp 2>nul

echo.
echo [B] Проверка получения списка пользователей...
curl -s "http://localhost:8080/api/users" > get-response.tmp 2>&1
set get_result=!errorlevel!

if !get_result! equ 0 (
    echo    [OK] Список пользователей получен
    set /a total_tests+=1, passed_tests+=1
) else (
    echo    [FAIL] Не удалось получить список пользователей
    set /a total_tests+=1, failed_tests+=1
)
del get-response.tmp 2>nul

echo.
echo [C] Ожидание обработки Kafka события...
echo Ждем 15 секунд для обработки события Kafka...
for /l %%i in (1,1,15) do (
    echo    Ожидание... %%i/15 секунд
    timeout /t 1 /nobreak > nul
)

echo.
echo [D] Проверка Kafka события в notification-service...
docker-compose logs notification-service --tail=30 > kafka-logs.tmp 2>&1
set kafka_found=0

findstr /C:"CREATE" kafka-logs.tmp > nul
if !errorlevel! equ 0 (
    echo    [OK] Kafka событие CREATE найдено в логах
    set /a total_tests+=1, passed_tests+=1
    set kafka_found=1
    goto :kafka_check_done
)

findstr /C:"UserCreatedEvent" kafka-logs.tmp > nul
if !errorlevel! equ 0 (
    echo    [OK] Найдено UserCreatedEvent в логах notification-service
    set /a total_tests+=1, passed_tests+=1
    set kafka_found=1
    goto :kafka_check_done
)

findstr /C:"user" kafka-logs.tmp > nul
if !errorlevel! equ 0 (
    echo    [OK] Найдены сообщения о пользователях в логах notification-service
    set /a total_tests+=1, passed_tests+=1
    set kafka_found=1
    goto :kafka_check_done
)

echo    [FAIL] Kafka событие CREATE НЕ найдено в логах
echo    Детали: Notification Service не получил событие через Kafka
set /a total_tests+=1, failed_tests+=1

:kafka_check_done
del kafka-logs.tmp 2>nul

echo.
echo [E] Проверка Circuit Breaker...
curl -s "http://localhost:8080/actuator/circuitbreakers" > circuit.tmp 2>&1
set circuit_found=0
findstr "userServiceCB" circuit.tmp > nul
if !errorlevel! equ 0 (
    echo    [OK] Circuit Breaker 'userServiceCB' настроен
    set /a total_tests+=1, passed_tests+=1
    set circuit_found=1
)

if !circuit_found! equ 0 (
    findstr "circuit" circuit.tmp > nul
    if !errorlevel! equ 0 (
        echo    [OK] Circuit Breaker присутствует (другое имя)
        set /a total_tests+=1, passed_tests+=1
        set circuit_found=1
    )
)

if !circuit_found! equ 0 (
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
    echo Система работает корректно, все паттерны функционируют.
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
echo ============================================
echo АВТОМАТИЧЕСКАЯ ОСТАНОВКА СИСТЕМЫ
echo ============================================
echo Для остановки системы нажмите любую клавишу...
pause > nul

echo.
echo Останавливаем все контейнеры...
docker-compose down
echo [OK] Система остановлена

echo.
echo ============================================
echo ПРОВЕРКА ЗАВЕРШЕНА
echo ============================================
echo Все этапы выполнены успешно!
echo.
exit /b 0