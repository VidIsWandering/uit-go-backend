@echo off
chcp 65001 >nul
REM ===========================================================================
REM View Service Logs
REM ===========================================================================

echo.
echo ========================================
echo   UIT-Go - Service Logs
echo ========================================
echo.
echo Select service to view logs:
echo.
echo   1. User Service
echo   2. Trip Service
echo   3. Driver Service
echo   4. Auth Service
echo   5. Nginx Gateway
echo   6. All Services (tail mode)
echo   7. Exit
echo.
set /p choice="Enter choice (1-7): "

if "%choice%"=="1" goto user_logs
if "%choice%"=="2" goto trip_logs
if "%choice%"=="3" goto driver_logs
if "%choice%"=="4" goto auth_logs
if "%choice%"=="5" goto nginx_logs
if "%choice%"=="6" goto all_logs
if "%choice%"=="7" goto end

echo Invalid choice
pause
exit /b 1

:user_logs
echo.
echo [User Service Logs - Last 50 lines]
docker-compose logs --tail=50 user-service
pause
exit /b 0

:trip_logs
echo.
echo [Trip Service Logs - Last 50 lines]
docker-compose logs --tail=50 trip-service
pause
exit /b 0

:driver_logs
echo.
echo [Driver Service Logs - Last 50 lines]
docker-compose logs --tail=50 driver-service
pause
exit /b 0

:auth_logs
echo.
echo [Auth Service Logs - Last 50 lines]
docker-compose logs --tail=50 auth-service
pause
exit /b 0

:nginx_logs
echo.
echo [Nginx Gateway Logs - Last 50 lines]
docker-compose logs --tail=50 nginx
pause
exit /b 0

:all_logs
echo.
echo [All Services - Tail Mode]
echo Press Ctrl+C to exit
docker-compose logs -f
exit /b 0

:end
exit /b 0
