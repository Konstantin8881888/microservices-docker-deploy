@echo off
call scripts\fix-encoding.bat
chcp 65001 > nul

echo ============================================
echo ТЕСТИРОВАНИЕ ВЗАИМОДЕЙСТВИЯ СЕРВИСОВ
echo ============================================

set total_tests=0
set passed_tests=0
set failed_tests=0

echo.
echo [ТЕСТ 1/5] Проверка доступности Gateway...
curl -s -f "http://localhost:8080/actuator/health" > nul 2>&1
if %errorlevel% equ 0 (
    echo [УСПЕХ] Gateway доступен
    set /a total_tests+=1, passed_tests+=1
) else (
    echo [ОШИБКА] Gateway недоступен
    set /a total_tests+=1, failed_tests+=1
    echo   Детали: Gateway не отвечает на http://localhost:8080
)

echo.
echo [ТЕСТ 2/5] Создание пользователя...
set /a random_num=%random% %% 10000
set TEST_EMAIL=test-%random_num%@docker.com
echo Тестовый email: %TEST_EMAIL%

curl -s -X POST "http://localhost:8080/api/users" -H "Content-Type: application/json" -d "{\"name\":\"Integration Test\",\"email\":\"%TEST_EMAIL%\",\"age\":30}" > post-response.tmp 2>&1
set post_result=%errorlevel%

if %post_result% equ 0 (
    echo [УСПЕХ] Пользователь создан
    set /a total_tests+=1, passed_tests+=1
) else (
    echo [ОШИБКА] Не удалось создать пользователя
    echo   Детали: Создание пользователя не удалось (email: %TEST_EMAIL%)
    echo Ответ сервера:
    type post-response.tmp
    set /a total_tests+=1, failed_tests+=1
)

del post-response.tmp 2>nul

echo.
echo [ТЕСТ 3/5] Проверка создания пользователя (получение списка)...
curl -s "http://localhost:8080/api/users" > get-response.tmp 2>&1
set get_result=%errorlevel%

if %get_result% equ 0 (
    echo [УСПЕХ] Список пользователей получен
    set /a total_tests+=1, passed_tests+=1
) else (
    echo [ОШИБКА] Не удалось получить список пользователей
    echo   Детали: Получение списка пользователей не удалось
    set /a total_tests+=1, failed_tests+=1
)

del get-response.tmp 2>nul

echo.
echo [ТЕСТ 4/5] Ожидание обработки Kafka события...
echo Ждем 15 секунд для обработки события Kafka...
for /l %%i in (1,1,15) do (
    echo Ожидание... %%i/15 секунд
    timeout /t 1 /nobreak > nul
)

echo.
echo [ТЕСТ 5/5] Проверка Kafka события в notification-service...
docker-compose logs notification-service --tail=30 > kafka-logs.tmp 2>&1
findstr /C:"CREATE" kafka-logs.tmp > nul
if %errorlevel% equ 0 (
    echo [УСПЕХ] Kafka событие CREATE найдено в логах
    set /a total_tests+=1, passed_tests+=1
) else (
    echo [ОШИБКА] Kafka событие CREATE НЕ найдено в логах
    echo   Детали: Notification Service не получил событие через Kafka
    echo Последние логи notification-service:
    type kafka-logs.tmp
    set /a total_tests+=1, failed_tests+=1
)

del kafka-logs.tmp 2>nul

echo.
echo ============================================
echo РЕЗУЛЬТАТЫ ТЕСТИРОВАНИЯ:
echo ============================================
echo Всего тестов: %total_tests%
echo Успешно: %passed_tests%
echo Неудачно: %failed_tests%

if %failed_tests% gtr 0 (
    echo.
    echo Обнаружены проблемы в %failed_tests% тестах из %total_tests%.
    echo Смотрите выше детали каждой ошибки.
) else (
    echo.
    echo Все тесты прошли успешно!
)