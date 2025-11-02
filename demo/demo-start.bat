@echo off
chcp 65001 >nul
REM ===========================================================================
REM Start UIT-Go Backend Stack
REM ===========================================================================

echo.
echo ========================================
echo   UIT-Go Backend - Starting...
echo ========================================
echo.

REM Check Docker
echo [Step 1/5] Checking Docker...
docker --version
if errorlevel 1 (
    echo [ERROR] Docker not found or not running
    pause & exit /b 1
)
echo [OK] Docker ready
echo.

REM Navigate to project
echo [Step 2/5] Navigating to project directory...
cd /d d:\uit-go-backend
if errorlevel 1 (
    echo [ERROR] Directory not found: d:\uit-go-backend
    pause & exit /b 1
)
echo [OK] Current dir: %CD%
echo.

REM Clean old environment
echo [Step 3/5] Cleaning old containers...
docker-compose down -v >nul 2>&1
echo [OK] Old containers removed
echo.

REM Build images
echo [Step 4/5] Building Docker images...
echo (This may take 2-3 minutes for first build)
docker-compose build
if errorlevel 1 (
    echo [ERROR] Build failed
    pause & exit /b 1
)
echo [OK] All images built
echo.

REM Start all services
echo [Step 5/5] Starting all services...
docker-compose up -d
if errorlevel 1 (
    echo [ERROR] Failed to start services
    pause & exit /b 1
)
echo [OK] All services started
echo.

REM Wait for services
echo Waiting 30 seconds for services to initialize...
timeout /t 30 /nobreak >nul
echo.

REM Show status
echo ========================================
echo   Container Status
echo ========================================
docker-compose ps
echo.

REM Show URLs
echo ========================================
echo   Service URLs
echo ========================================
echo.
echo   API Gateway:     http://localhost:8088
echo   User Service:    http://localhost:8080
echo   Trip Service:    http://localhost:8081
echo   Driver Service:  http://localhost:8082
echo   Prometheus:      http://localhost:9090
echo   Grafana:         http://localhost:3001 (admin/admin)
echo.
echo ========================================
echo   Next Steps
echo ========================================
echo.
echo   1. Check health:  demo-health-check.bat
echo   2. Run tests:     demo-test-flow.bat
echo   3. View logs:     demo-show-logs.bat
echo   4. Stop all:      docker-compose down
echo.
pause
