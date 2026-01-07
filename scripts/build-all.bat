@echo off
call scripts/fix-encoding.bat
chcp 65001 > nul
echo ============================================
echo СБОРКА ВСЕХ МИКРОСЕРВИСОВ
echo ============================================

echo.
echo [1/5] Сборка Eureka Server...
cd ..\eureka-server
call mvn clean package -DskipTests -Dmaven.test.skip=true -q
if %ERRORLEVEL% NEQ 0 (
    echo ✗ Ошибка сборки Eureka Server
    pause
    exit /b 1
)
echo ✓ Eureka Server собран

echo.
echo [2/5] Сборка Config Server...
cd ..\config-server
call mvn clean package -DskipTests -Dmaven.test.skip=true -q
if %ERRORLEVEL% NEQ 0 (
    echo ✗ Ошибка сборки Config Server
    pause
    exit /b 1
)
echo ✓ Config Server собран

echo.
echo [3/5] Сборка User Service...
cd ..\user-service
call mvn clean package -DskipTests -Dmaven.test.skip=true -q
if %ERRORLEVEL% NEQ 0 (
    echo ✗ Ошибка сборки User Service
    pause
    exit /b 1
)
echo ✓ User Service собран

echo.
echo [4/5] Сборка Notification Service...
cd ..\notification-service
call mvn clean package -DskipTests -Dmaven.test.skip=true -q
if %ERRORLEVEL% NEQ 0 (
    echo ✗ Ошибка сборки Notification Service
    pause
    exit /b 1
)
echo ✓ Notification Service собран

echo.
echo [5/5] Сборка API Gateway...
cd ..\api-gateway
echo Проверяем pom.xml...
if not exist "pom.xml" (
    echo ✗ Файл pom.xml не найден!
    pause
    exit /b 1
)

echo Запускаем сборку...
call mvn clean package -DskipTests -Dmaven.test.skip=true -q
if %ERRORLEVEL% NEQ 0 (
    echo ⚠️ Сборка с -q не удалась, пробуем с подробным выводом...
    call mvn clean package -DskipTests -Dmaven.test.skip=true
    if %ERRORLEVEL% NEQ 0 (
        echo ✗ Ошибка сборки API Gateway
        echo Проверьте, что зависимость spring-boot-starter-webflux в pom.xml без scope test
        pause
        exit /b 1
    )
)
echo ✓ API Gateway собран

echo.
cd ..\docker-deploy
echo ============================================
echo ВСЕ МИКРОСЕРВИСЫ УСПЕШНО СОБРАНЫ!
echo ============================================
echo Проверяем JAR-файлы...
call scripts\check-build.bat
pause