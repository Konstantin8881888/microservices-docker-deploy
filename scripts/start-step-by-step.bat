@echo off
call scripts/fix-encoding.bat
echo ============================================
echo ПОШАГОВЫЙ ЗАПУСК MICROSERVICES
echo ============================================

echo.
echo 1. Останавливаем всё...
docker-compose down

echo.
echo 2. Запускаем инфраструктуру...
docker-compose up -d postgres zookeeper kafka

echo.
echo Ожидаем запуска инфраструктуры...
timeout /t 30 /nobreak

echo.
echo 3. Запускаем Eureka...
docker-compose up -d eureka-server

echo.
echo Ожидаем запуска Eureka...
timeout /t 20 /nobreak

echo.
echo 4. Запускаем Config Server...
docker-compose up -d config-server

echo.
echo Ожидаем запуска Config Server...
timeout /t 20 /nobreak

echo.
echo 5. Запускаем микросервисы...
docker-compose up -d user-service notification-service

echo.
echo Ожидаем запуска микросервисов...
timeout /t 30 /nobreak

echo.
echo 6. Запускаем API Gateway...
docker-compose up -d api-gateway

echo.
echo Ожидаем полного запуска...
timeout /t 20 /nobreak

echo.
echo ============================================
echo СТАТУС КОНТЕЙНЕРОВ:
echo ============================================
docker-compose ps

echo.
echo ============================================
echo ДЛЯ ПРОВЕРКИ:
echo ============================================
echo 1. Eureka: http://localhost:8761
echo 2. Gateway: http://localhost:8080/api/users
echo 3. User Service: http://localhost:8081/actuator/health
echo 4. Config Server: http://localhost:8888/user-service/default
echo.
echo ============================================
echo ЛОГИ:
echo ============================================
echo docker-compose logs config-server
echo docker-compose logs kafka
echo docker-compose logs user-service

pause