@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo.
echo ====================================================================
echo   [US2] Estimate Price and Create Trip (API responses + DB verification)
echo ====================================================================
echo.

REM Direct service URLs (not through gateway)
set "TRIP_URL=http://localhost:8081"
set "USER_URL=http://localhost:8080"

REM Database connection settings (containers from docker-compose)
set "TRIP_DB=uit-go-backend-postgres-trip-1"
set "TRIP_DB_NAME=uit_trip_db"
set "TRIP_DB_USER=uit_go_trip"

REM Output folder is this script directory
set "OUT_DIR=%~dp0"

REM Try to load token and passenger id from previous US1 run
for /f "delims=" %%a in ('powershell -Command "(Get-Content '%OUT_DIR%p_token.json' -ErrorAction SilentlyContinue | ConvertFrom-Json).access_token"') do set P_TOKEN=%%a
for /f "delims=" %%a in ('powershell -Command "(Get-Content '%OUT_DIR%p_reg.json' -ErrorAction SilentlyContinue | ConvertFrom-Json).id"') do set P_ID=%%a

if "%P_TOKEN%"=="" (
    echo [INFO] JWT token not found. Running US1 script to obtain prerequisites...
    call "%OUT_DIR%demo-us1.bat"
    for /f "delims=" %%a in ('powershell -Command "(Get-Content '%OUT_DIR%p_token.json' -ErrorAction SilentlyContinue | ConvertFrom-Json).access_token"') do set P_TOKEN=%%a
    for /f "delims=" %%a in ('powershell -Command "(Get-Content '%OUT_DIR%p_reg.json' -ErrorAction SilentlyContinue | ConvertFrom-Json).id"') do set P_ID=%%a
)

if "%P_TOKEN%"=="" (
    echo [ERROR] Missing JWT token after attempting US1. Cannot proceed.
    exit /b 1
)

if "%P_ID%"=="" (
    echo [ERROR] Missing passenger ID after attempting US1. Cannot proceed.
    exit /b 1
)

echo Passenger ID: %P_ID%
echo.

echo [Step 1/2] Estimate trip price
echo Origin: (10.87, 106.803)
echo Destination: (10.815, 106.75)
echo.

curl.exe -s -X POST %TRIP_URL%/trips/estimate ^
  -H "Content-Type: application/json" ^
  -d "{\"origin\":{\"latitude\":10.87,\"longitude\":106.803},\"destination\":{\"latitude\":10.815,\"longitude\":106.75}}" ^
  -o "%OUT_DIR%estimate.json"

echo [Response]
type "%OUT_DIR%estimate.json"
echo.

echo [Step 2/2] Create trip with JWT authentication
echo.

curl.exe -s -X POST %TRIP_URL%/trips ^
  -H "Content-Type: application/json" ^
  -H "Authorization: Bearer %P_TOKEN%" ^
  -d "{\"passengerId\":\"%P_ID%\",\"origin\":{\"latitude\":10.87,\"longitude\":106.803},\"destination\":{\"latitude\":10.815,\"longitude\":106.75}}" ^
  -o "%OUT_DIR%trip.json"

echo [Response]
type "%OUT_DIR%trip.json"
echo.

for /f "delims=" %%a in ('powershell -Command "(Get-Content '%OUT_DIR%trip.json' -ErrorAction SilentlyContinue | ConvertFrom-Json).id"') do set TRIP_ID=%%a

if "%TRIP_ID%"=="" (
    echo [ERROR] Failed to create trip - check response above
    exit /b 1
)

echo Trip ID: %TRIP_ID%
echo.

echo [DB CHECK] Query trip record by id
echo.
docker exec -i %TRIP_DB% psql -U %TRIP_DB_USER% -d %TRIP_DB_NAME% -c "SELECT id, passenger_id, status, price, origin_latitude, origin_longitude, destination_latitude, destination_longitude, created_at FROM trips WHERE id='%TRIP_ID%';"
echo.

echo [DONE] US2 completed successfully.
echo Outputs saved in: %OUT_DIR%

if not defined NO_PAUSE pause
exit /b 0
