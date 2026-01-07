     @echo off
     call scripts/fix-encoding.bat
     echo ============================================
     echo ДИАГНОСТИКА СИСТЕМЫ
     echo ============================================

     echo.
     echo 1. Проверка контейнеров...
     docker-compose ps

     echo.
     echo 2. Проверка Config Server volume...
     docker-compose exec config-server ls -la /config-repo

     echo.
     echo 3. Проверка Config Server API...
     curl -s http://localhost:8888/user-service/default | jq '.propertySources[0].name'

     echo.
     echo 4. Проверка Eureka...
     curl -s http://localhost:8761/eureka/apps | grep -o "<name>[^<]*</name>"

     echo.
     echo 5. Проверка логов User Service...
     docker-compose logs user-service --tail=20

     pause