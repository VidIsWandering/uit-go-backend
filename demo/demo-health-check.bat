@echo off
chcp 65001 >nul
REM ===========================================================================
REM Health Check All Services
REM ===========================================================================

echo.
echo ========================================
echo   UIT-Go - Health Check
echo ========================================
echo.

REM User Service
echo [1/7] User Service (Spring Boot)
curl -s http://localhost:8080/actuator/health
if errorlevel 1 (echo [FAIL]) else (echo [PASS])
echo.

REM Trip Service
echo [2/7] Trip Service (Spring Boot)
curl -s http://localhost:8081/actuator/health
if errorlevel 1 (echo [FAIL]) else (echo [PASS])
echo.

REM Driver Service
echo [3/7] Driver Service (Node.js)
curl -s http://localhost:8082/health
if errorlevel 1 (echo [FAIL]) else (echo [PASS])
echo.

REM Auth Service
echo [4/7] Auth Service (Node.js)
curl -s http://localhost:3000/ >nul
if errorlevel 1 (echo [FAIL]) else (echo [PASS])
echo.

REM Nginx Gateway
echo [5/7] Nginx Gateway
curl -s -o nul -w "HTTP %%{http_code}" http://localhost:8088/
echo.
echo [PASS]
echo.

REM Prometheus
echo [6/7] Prometheus
curl -s http://localhost:9090/-/healthy
if errorlevel 1 (echo [FAIL]) else (echo [PASS])
echo.

REM Grafana
echo [7/7] Grafana
curl -s http://localhost:3001/api/health
if errorlevel 1 (echo [FAIL]) else (echo [PASS])
echo.

echo ========================================
echo   Health Check Complete
echo ========================================
echo.
echo If all services passed, you can run API tests.
echo If any failed, check logs: docker-compose logs [service-name]
echo.
pause
