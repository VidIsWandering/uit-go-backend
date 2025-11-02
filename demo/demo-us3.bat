@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo.
echo ====================================================================
echo   [US3] Trip -> Driver Service call proof (seed + API + logs)
echo ====================================================================
echo.

REM Service URLs
set "TRIP_URL=http://localhost:8081"
set "DRIVER_URL=http://localhost:8082"

REM Output folder
set "OUT_DIR=%~dp0"

REM Ensure token (from US1)
for /f "delims=" %%a in ('powershell -Command "(Get-Content '%OUT_DIR%p_token.json' -ErrorAction SilentlyContinue | ConvertFrom-Json).access_token"') do set P_TOKEN=%%a
if "%P_TOKEN%"=="" (
  echo [INFO] JWT token not found. Running US1 script...
  call "%OUT_DIR%demo-us1.bat"
  for /f "delims=" %%a in ('powershell -Command "(Get-Content '%OUT_DIR%p_token.json' -ErrorAction SilentlyContinue | ConvertFrom-Json).access_token"') do set P_TOKEN=%%a
)
if "%P_TOKEN%"=="" (
  echo [ERROR] Missing JWT token after US1. Cannot proceed.
  goto :end
)

REM Ensure there is at least one trip (from US2)
for /f "delims=" %%a in ('powershell -Command "(Get-Content '%OUT_DIR%trip.json' -ErrorAction SilentlyContinue | ConvertFrom-Json).id"') do set TRIP_ID=%%a
if "%TRIP_ID%"=="" (
  echo [INFO] No trip found. Running US2 script to create one...
  set NO_PAUSE=1
  call "%OUT_DIR%demo-us2.bat"
  for /f "delims=" %%a in ('powershell -Command "(Get-Content '%OUT_DIR%trip.json' -ErrorAction SilentlyContinue | ConvertFrom-Json).id"') do set TRIP_ID=%%a
)
if "%TRIP_ID%"=="" (
  echo [ERROR] Missing Trip ID after US2. Cannot proceed.
  goto :end
)

echo [Step 1/3] Seed driver data in Redis via Driver Service APIs
set "DRIVER1=11111111-1111-1111-1111-111111111111"
set "DRIVER2=22222222-2222-2222-2222-222222222222"

echo - Put driver locations near HCMC
curl.exe -s -X PUT %DRIVER_URL%/drivers/%DRIVER1%/location -H "Content-Type: application/json" -d "{\"latitude\":10.82,\"longitude\":106.63}" >nul
curl.exe -s -X PUT %DRIVER_URL%/drivers/%DRIVER2%/location -H "Content-Type: application/json" -d "{\"latitude\":10.85,\"longitude\":106.70}" >nul

echo - Set driver ONLINE
curl.exe -s -X PUT %DRIVER_URL%/drivers/%DRIVER1%/status -H "Content-Type: application/json" -d "{\"status\":\"ONLINE\"}" >nul
curl.exe -s -X PUT %DRIVER_URL%/drivers/%DRIVER2%/status -H "Content-Type: application/json" -d "{\"status\":\"ONLINE\"}" >nul
echo   Done seeding drivers: %DRIVER1%, %DRIVER2%
echo.

echo [Step 2/3] Call Trip Service to get available trips for current user (uses driver location via Driver Service)
curl.exe -s -X GET %TRIP_URL%/trips/available -H "Authorization: Bearer %P_TOKEN%" -o "%OUT_DIR%available.json"
echo [Response]
type "%OUT_DIR%available.json"
echo.

echo [Step 3/3] Proof via logs: Trip -> Driver HTTP call
echo - Trip Service outbound HTTP lines:
docker-compose logs trip-service --tail=200 | findstr /i "http.client.trip-service Outbound HTTP http://driver-service"
echo.
echo - Driver Service inbound logs (should include 'Lấy vị trí cho tài xế'):
docker-compose logs driver-service --tail=100
echo.

echo [DONE] US3 demo completed. Outputs saved in: %OUT_DIR%

:end
if not defined NO_PAUSE pause
exit /b 0
