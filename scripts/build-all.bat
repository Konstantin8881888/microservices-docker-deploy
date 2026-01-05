@echo off
echo ============================================
echo СБОРКА ВСЕХ МИКРОСЕРВИСОВ
echo ============================================

echo.
echo [1/5] Сборка Eureka Server...
cd ..\eureka-server
call mvn clean package -DskipTests
if %ERRORLEVEL% NEQ 0 (
    echo ✗ Ошибка сборки Eureka Server
    pause
    exit /b 1
)
echo ✓ Eureka Server собран

echo.
echo [2/5] Сборка Config Server...
cd ..\config-server
call mvn clean package -DskipTests
if %ERRORLEVEL% NEQ 0 (
    echo ✗ Ошибка сборки Config Server
    pause
    exit /b 1
)
echo ✓ Config Server собран

echo.
echo [3/5] Сборка User Service...
cd ..\Module2
call mvn clean package -DskipTests
if %ERRORLEVEL% NEQ 0 (
    echo ✗ Ошибка сборки User Service
    pause
    exit /b 1
)
echo ✓ User Service собран

echo.
echo [4/5] Сборка Notification Service...
cd ..\notification-service
call mvn clean package -DskipTests
if %ERRORLEVEL% NEQ 0 (
    echo ✗ Ошибка сборки Notification Service
    pause
    exit /b 1
)
echo ✓ Notification Service собран

echo.
echo [5/5] Сборка API Gateway...
cd ..\api-gateway
call mvn clean package -DskipTests
if %ERRORLEVEL% NEQ 0 (
    echo ✗ Ошибка сборки API Gateway
    pause
    exit /b 1
)
echo ✓ API Gateway собран

echo.
cd ..\docker-deploy
echo ============================================
echo ВСЕ МИКРОСЕРВИСЫ УСПЕШНО СОБРАНЫ!
echo ============================================
echo Следующий шаг: docker-compose build
pause