@echo off
call scripts/fix-encoding.bat
echo ============================================
echo ПРОВЕРКА СОБРАННЫХ JAR-ФАЙЛОВ
echo ============================================

echo.
echo Проверка наличия JAR-файлов:

set ERROR_COUNT=0

echo.
echo [1] Eureka Server:
dir ..\eureka-server\target\*.jar > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ✓ Найден
) else (
    echo ✗ Не найден
    set /a ERROR_COUNT+=1
)

echo.
echo [2] Config Server:
dir ..\config-server\target\*.jar > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ✓ Найден
) else (
    echo ✗ Не найден
    set /a ERROR_COUNT+=1
)

echo.
echo [3] User Service:
dir ..\user-service\target\*.jar > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ✓ Найден
) else (
    echo ✗ Не найден
    set /a ERROR_COUNT+=1
)

echo.
echo [4] Notification Service:
dir ..\notification-service\target\*.jar > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ✓ Найден
) else (
    echo ✗ Не найден
    set /a ERROR_COUNT+=1
)

echo.
echo [5] API Gateway:
dir ..\api-gateway\target\*.jar > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ✓ Найден
) else (
    echo ✗ Не найден
    set /a ERROR_COUNT+=1
)

echo.
if %ERROR_COUNT% EQU 0 (
    echo ============================================
    echo ВСЕ JAR-ФАЙЛЫ УСПЕШНО СОБРАНЫ!
    echo ============================================
) else (
    echo ============================================
    echo ОБНАРУЖЕНО %ERROR_COUNT% ОШИБОК!
    echo ============================================
)

pause