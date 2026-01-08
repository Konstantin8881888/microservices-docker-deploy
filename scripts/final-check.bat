@echo off
call scripts\fix-encoding.bat
chcp 65001 > nul

echo ============================================
echo ФИНАЛЬНАЯ ПРОВЕРКА ЗАДАНИЯ
echo ============================================
echo Проверка всех паттернов в Docker-окружении
echo.

set total_tests=0
set passed_tests=0
set failed_tests=0

echo [ПРОВЕРКА 1/6] Service Discovery (Eureka)...
docker-compose exec eureka-server curl -s http://localhost:8761/actuator/health | findstr "UP" > nul
if %errorlevel% equ 0 (
    echo [УСПЕХ] Eureka Server работает
    set /a total_tests+=1, passed_tests+=1
) else (
    echo [ОШИБКА] Eureka Server не работает
    set /a total_tests+=1, failed_tests+=1
)

echo.
echo [ПРОВЕРКА 2/6] External Configuration (Config Server)...
docker-compose exec config-server curl -s http://localhost:8888/actuator/health | findstr "UP" > nul
if %errorlevel% equ 0 (
    echo [УСПЕХ] Config Server работает
    set /a total_tests+=1, passed_tests+=1
) else (
    echo [ОШИБКА] Config Server не работает
    set /a total_tests+=1, failed_tests+=1
)

echo.
echo [ПРОВЕРКА 3/6] API Gateway...
docker-compose exec api-gateway curl -s http://localhost:8080/actuator/health | findstr "UP" > nul
if %errorlevel% equ 0 (
    echo [УСПЕХ] API Gateway работает
    set /a total_tests+=1, passed_tests+=1
) else (
    echo [ОШИБКА] API Gateway не работает
    set /a total_tests+=1, failed_tests+=1
)

echo.
echo [ПРОВЕРКА 4/6] Circuit Breaker...
curl -s http://localhost:8080/actuator/circuitbreakers | findstr "userServiceCB" > nul
if %errorlevel% equ 0 (
    echo [УСПЕХ] Circuit Breaker настроен
    set /a total_tests+=1, passed_tests+=1
) else (
    echo [ОШИБКА] Circuit Breaker не настроен
    set /a total_tests+=1, failed_tests+=1
)

echo.
echo [ПРОВЕРКА 5/6] Взаимодействие микросервисов...
set /a random_num=%random% %% 10000
set TEST_EMAIL=final-test-%random_num%@docker.com
echo Создаем тестового пользователя (email: %TEST_EMAIL%)...

curl -s -X POST "http://localhost:8080/api/users" -H "Content-Type: application/json" -d "{\"name\":\"Final Test\",\"email\":\"%TEST_EMAIL%\",\"age\":35}" > nul
set create_result=%errorlevel%

if %create_result% equ 0 (
    echo [УСПЕХ] Пользователь создан через Gateway
    set /a total_tests+=1, passed_tests+=1
) else (
    echo [ОШИБКА] Не удалось создать пользователя
    set /a total_tests+=1, failed_tests+=1
)

echo Ожидание обработки Kafka события...
timeout /t 10 /nobreak > nul

echo.
echo [ПРОВЕРКА 6/6] Проверка Kafka взаимодействия...
docker-compose logs notification-service --tail=20 | findstr "CREATE" > nul
if %errorlevel% equ 0 (
    echo [УСПЕХ] Взаимодействие через Kafka работает
    set /a total_tests+=1, passed_tests+=1
) else (
    echo [ОШИБКА] Проблема с Kafka взаимодействием
    set /a total_tests+=1, failed_tests+=1
)

echo.
echo ============================================
echo ИТОГОВЫЙ ОТЧЕТ
echo ============================================
echo Всего проверок: %total_tests%
echo Успешно: %passed_tests%
echo Неудачно: %failed_tests%
echo.

echo ============================================
echo СВОДКА ПО ПАТТЕРНАМ:
echo ============================================
echo.
echo 1. Service Discovery: если Eureka работает - РАБОТАЕТ
echo 2. External Configuration: если Config Server работает - РАБОТАЕТ
echo 3. API Gateway: если Gateway работает - РАБОТАЕТ
echo 4. Circuit Breaker: если Circuit Breaker настроен - РАБОТАЕТ
echo 5. Взаимодействие сервисов: если пользователь создан и Kafka событие получено - РАБОТАЕТ
echo.

if %failed_tests% equ 0 (
    echo ============================================
    echo ВСЕ ПАТТЕРНЫ РАБОТАЮТ КОРРЕКТНО!
    echo ============================================
    echo Система успешно развернута в Docker и сервисы корректно взаимодействуют.
) else (
    echo ============================================
    echo ОБНАРУЖЕНЫ ПРОБЛЕМЫ С НЕКОТОРЫМИ ПАТТЕРНАМИ
    echo ============================================
)

echo.
echo Для остановки системы выполните: docker-compose down
echo.
pause