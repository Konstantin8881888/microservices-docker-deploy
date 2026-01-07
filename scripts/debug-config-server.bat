@echo off
call scripts/fix-encoding.bat
echo ============================================
echo ОТЛАДКА CONFIG SERVER
echo ============================================

echo.
echo 1. Останавливаем config-server...
docker-compose stop config-server

echo.
echo 2. Запускаем с выводом логов...
docker-compose up --force-recreate config-server