@echo off
call scripts/fix-encoding.bat
echo ============================================
echo ЗАПУСК MICROSERVICES В DOCKER
echo ============================================

echo.
echo Останавливаем предыдущие контейнеры...
docker-compose down

echo.
echo Собираем Docker образы...
docker-compose build --no-cache

echo.
echo Запускаем все сервисы...
docker-compose up -d

echo.
echo Ожидаем запуска сервисов...
timeout /t 60 /nobreak

echo.
echo ============================================
echo СТАТУС КОНТЕЙНЕРОВ:
echo ============================================
docker-compose ps

echo.
echo ============================================
echo ДЛЯ ПРОВЕРКИ ОТКРОЙТЕ:
echo ============================================
echo 1. Eureka Dashboard:  http://localhost:8761
echo 2. API Gateway:       http://localhost:8080/api/users
echo 3. User Service:      http://localhost:8081/actuator/health
echo 4. Config Server:     http://localhost:8888/user-service/default
echo.
echo ============================================
echo ДЛЯ ПРОСМОТРА ЛОГОВ:
echo ============================================
echo docker-compose logs -f user-service
echo docker-compose logs -f api-gateway
echo.
echo ============================================
echo ДЛЯ ОСТАНОВКИ:
echo ============================================
echo docker-compose down
echo.
pause