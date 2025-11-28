@echo off
chcp 65001 >nul
REM ===========================================================================
REM Cleanup UIT-Go Backend Stack
REM ===========================================================================

echo.
echo ========================================
echo   UIT-Go - Cleanup
echo ========================================
echo.
echo WARNING: This will:
echo   - Stop all containers
echo   - Remove all containers
echo   - Remove all volumes (database data will be lost)
echo   - Remove networks
echo.
set /p confirm="Continue? (y/n): "

if /i not "%confirm%"=="y" (
    echo Cancelled
    exit /b 0
)

echo.
echo Stopping and removing all containers...
docker-compose down -v

if errorlevel 1 (
    echo [ERROR] Cleanup failed
    pause
    exit /b 1
)

echo.
echo [OK] Cleanup complete
echo.
echo All containers, volumes, and networks removed.
echo To start again, run: demo-start.bat
echo.
pause
