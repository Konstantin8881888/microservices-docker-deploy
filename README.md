# Микросервисная система с Spring Cloud

Полная система микросервисов с использованием Spring Cloud паттернов:
- ✅ **Service Discovery** (Eureka Server)
- ✅ **External Configuration** (Config Server)
- ✅ **API Gateway** с Circuit Breaker
- ✅ **Микросервисы**: User Service и Notification Service
- ✅ **Инфраструктура**: PostgreSQL, Kafka

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
## 📋 Требования к системе

Перед запуском убедитесь, что установлено:

| Компонент | Версия | Ссылка |
|-----------|--------|--------|
| **Java** | 17+ | [Adoptium](https://adoptium.net/) |
| **Maven** | 3.8+ | [Apache Maven](https://maven.apache.org/) |
| **Docker** | 24+ | [Docker Desktop](https://www.docker.com/products/docker-desktop/) |
| **Docker Compose** | 2.20+ | (входит в Docker Desktop) |
| **Git** | 2.40+ | [Git](https://git-scm.com/) |

**Проверка установки:**

    java -version
    mvn -v
    docker --version
    docker-compose --version
    git --version
---
# 🚀 Быстрый старт
## 1. Клонирование и подготовка

### 1. Клонируйте репозиторий
    git clone https://github.com/Konstantin8881888/microservices-docker-deploy.git
    cd docker-deploy

### 2. Запустите скрипт подготовки - он сам скачает все модули!
    scripts\prepare-branches.bat

### 3. Соберите все микросервисы
    scripts\build-all.bat
## 2. Запуск системы

### Вариант A: Полный запуск одним скриптом
    scripts\run-all.bat

### Вариант B: Пошаговый запуск (рекомендуется для проверки минимального взаимодействия и работы микросервисов)
    scripts\start-step-by-step.bat
## 3. Проверка работы
После запуска откройте в браузере:


| URL                                     | Ожидаемый результат                                                            |
| -----------------------------------------|--------------------------------------------------------------------------------|
| [**Eureka Dashboard**](http://localhost:8761)                    | Все 5 сервисов в статусе UP (4 явно, Eureka подразумевается работой эндпойнта) |
| [**API Gateway**](http://localhost:8080/api/users)               | Список пользователей (JSON)                                                    |
| [**User Service Health**](http://localhost:8081/actuator/health) | Должен быть {"status":"UP"}                                                    |
| [**Config Server**](http://localhost:8888/user-service/default)      | Конфигурация в JSON                                                     |
---
# 📦 Что скачивает скрипт prepare-branches.bat
Скрипт автоматически клонирует 5 репозиториев в соседние папки:

| Модуль | Ветка (актуальная) | Описание |
|-----------|-----------------------------------------------------------------------------------------|------------------------------------------------|
| **user-service** | [**feature4**](https://github.com/Konstantin8881888/user-service) | CRUD API для пользователей                     |
| **notification-service** | [**feature2**](https://github.com/Konstantin8881888/notification-service/tree/feature2) | Отправка email через Kafka |
| **eureka-server**| [**feature**](https://github.com/Konstantin8881888/eureka-server) | Service Discovery                  |
| **config-server**| [**feature**](https://github.com/Konstantin8881888/config-server) | Централизованная конфигурация                   |
| **api-gateway** | [**feature**](https://github.com/Konstantin8881888/api-gateway) | Единая точка входа + Circuit Breaker                 |
---