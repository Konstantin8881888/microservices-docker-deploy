# Microservices Docker Deployment

Деплой микросервисной системы с Spring Cloud.

## Компоненты:
1. **Service Discovery**: Eureka Server (8761)
2. **External Configuration**: Config Server (8888)
3. **API Gateway**: Spring Cloud Gateway (8080)
4. **Circuit Breaker**: Resilience4j в Gateway
5. **Микросервисы**:
    - User Service (8081)
    - Notification Service (8082)
6. **Инфраструктура**:
    - PostgreSQL (5432)
    - Kafka (9092)
---
## Запуск:

    # 1. Подготовить ветки
    scripts/prepare-branches.bat
    
    # 2. Собрать все сервисы
    scripts/build-all.bat
    
    # 3. Запустить Docker Compose
    scripts/run-all.bat
---
## Проверка:
Eureka: http://localhost:8761

Gateway: http://localhost:8080/api/users

---

