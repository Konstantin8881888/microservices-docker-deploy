@echo off
echo ============================================
echo ПОДГОТОВКА ВЕТОК ДЛЯ DOCKER-СБОРКИ
echo ============================================

echo.
echo [1/5] User Service (Module2) - ветка feature4
cd ..\Module2
git checkout feature4
git pull origin feature4
echo ✓ User Service готов

echo.
echo [2/5] Notification Service - ветка feature2
cd ..\notification-service
git checkout feature2
git pull origin feature2
echo ✓ Notification Service готов

echo.
echo [3/5] Eureka Server - ветка master
cd ..\eureka-server
git checkout master
git pull origin master
echo ✓ Eureka Server готов

echo.
echo [4/5] Config Server - ветка master
cd ..\config-server
git checkout master
git pull origin master
echo ✓ Config Server готов

echo.
echo [5/5] API Gateway - ветка master
cd ..\api-gateway
git checkout master
git pull origin master
echo ✓ API Gateway готов

echo.
cd ..\docker-deploy
echo ============================================
echo ВСЕ РЕПОЗИТОРИИ ПОДГОТОВЛЕНЫ!
echo ============================================
pause