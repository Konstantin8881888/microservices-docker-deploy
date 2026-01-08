@echo off
chcp 65001 > nul
echo ============================================
echo ПРОВЕРКА СОБРАННЫХ JAR-ФАЙЛОВ
echo ============================================

set total_checks=0
set found_jars=0
set missing_jars=0

echo.
echo Проверка наличия JAR-файлов:

echo.
echo [1] Eureka Server:
dir ..\eureka-server\target\*.jar > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo    [OK] Найден
    set /a total_checks+=1, found_jars+=1
) else (
    echo    [FAIL] Не найден
    set /a total_checks+=1, missing_jars+=1
)

echo.
echo [2] Config Server:
dir ..\config-server\target\*.jar > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo    [OK] Найден
    set /a total_checks+=1, found_jars+=1
) else (
    echo    [FAIL] Не найден
    set /a total_checks+=1, missing_jars+=1
)

echo.
echo [3] User Service:
dir ..\user-service\target\*.jar > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo    [OK] Найден
    set /a total_checks+=1, found_jars+=1
) else (
    echo    [FAIL] Не найден
    set /a total_checks+=1, missing_jars+=1
)

echo.
echo [4] Notification Service:
dir ..\notification-service\target\*.jar > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo    [OK] Найден
    set /a total_checks+=1, found_jars+=1
) else (
    echo    [FAIL] Не найден
    set /a total_checks+=1, missing_jars+=1
)

echo.
echo [5] API Gateway:
dir ..\api-gateway\target\*.jar > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo    [OK] Найден
    set /a total_checks+=1, found_jars+=1
) else (
    echo    [FAIL] Не найден
    set /a total_checks+=1, missing_jars+=1
)

echo.
if %missing_jars% EQU 0 (
    echo ============================================
    echo ВСЕ JAR-ФАЙЛЫ УСПЕШНО СОБРАНЫ!
    echo ============================================
) else (
    echo ============================================
    echo ОБНАРУЖЕНО %missing_jars% ОШИБОК!
    echo ============================================
)

echo.