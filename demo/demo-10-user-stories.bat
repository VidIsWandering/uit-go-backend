@echo off
chcp 65001 >nul
REM ===========================================================================
REM Interactive Demo - 10 User Stories Step by Step
REM Each story can be executed individually with inter-service verification
REM ===========================================================================

setlocal enabledelayedexpansion

echo.
echo ========================================
echo   UIT-Go - Interactive Demo
echo   10 User Stories Step-by-Step
echo ========================================
echo.

set BASE_URL=http://localhost:8088/api

REM Database connection settings
set USER_DB=postgres-user
set USER_DB_NAME=user_service_db
set USER_DB_USER=user_admin
set TRIP_DB=postgres-trip
set TRIP_DB_NAME=trip_service_db
set TRIP_DB_USER=trip_admin

REM Initialize variables
set P_EMAIL=
set P_PASSWORD=
set P_ID=
set P_TOKEN=
set D_EMAIL=
set D_PASSWORD=
set D_ID=
set D_TOKEN=
set TRIP_ID=

REM ===========================================================================
REM MAIN MENU
REM ===========================================================================
:menu
cls
echo.
echo ====================================================================
echo   UIT-Go - Interactive Demo Menu
echo ====================================================================
echo.
echo PASSENGER FLOW:
echo   1. [Passenger US1] Register and Login
echo   2. [Passenger US2] Estimate Price and Create Trip
echo   3. [Passenger US3] Track Driver Location (Polling)
echo   4. [Passenger US4] Cancel Trip
echo   5. [Passenger US5] Rate Trip and View History
echo.
echo DRIVER FLOW:
echo   6. [Driver US1] Register with Vehicle Info and Login
echo   7. [Driver US2] Set Status to ONLINE
echo   8. [Driver US3] View Available Trips and Accept
echo   9. [Driver US4] Update Location and Start Trip
echo   10. [Driver US5] Complete Trip and View Earnings
echo.
echo UTILITIES:
echo   11. Check Inter-Service Communication Logs
echo   12. View All Service Logs
echo   13. Show Current Test Data
echo   14. Run All Stories Automatically
echo   15. Cleanup and Exit
echo.
set /p choice="Enter your choice (1-15): "

if "%choice%"=="1" goto passenger_us1
if "%choice%"=="2" goto passenger_us2
if "%choice%"=="3" goto passenger_us3
if "%choice%"=="4" goto passenger_us4
if "%choice%"=="5" goto passenger_us5
if "%choice%"=="6" goto driver_us1
if "%choice%"=="7" goto driver_us2
if "%choice%"=="8" goto driver_us3
if "%choice%"=="9" goto driver_us4
if "%choice%"=="10" goto driver_us5
if "%choice%"=="11" goto check_logs
if "%choice%"=="12" goto view_all_logs
if "%choice%"=="13" goto show_data
if "%choice%"=="14" goto run_all
if "%choice%"=="15" goto cleanup
echo Invalid choice!
pause
goto menu

REM ===========================================================================
REM PASSENGER US1: Register and Login
REM ===========================================================================
:passenger_us1
cls
echo.
echo ====================================================================
echo   [Passenger US1] Register and Login
echo ====================================================================
echo.
echo This story demonstrates:
echo   - User registration with PASSENGER role
echo   - JWT authentication via login
echo   - Token generation and storage
echo.
echo Services involved:
echo   - User Service: Register user, validate credentials
echo   - Auth Service: Generate JWT token
echo.
pause

REM Register
set P_EMAIL=passenger_%RANDOM%@uit.edu.vn
set P_PASSWORD=Pass123!

echo.
echo [Step 1/2] Registering passenger...
echo Email: %P_EMAIL%
echo Password: %P_PASSWORD%
echo.

curl -s -X POST %BASE_URL%/users ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"%P_EMAIL%\",\"password\":\"%P_PASSWORD%\",\"fullName\":\"Nguyen Van A\",\"phone\":\"0909123456\",\"role\":\"PASSENGER\"}" ^
  -o p_reg.json

echo [Response]
type p_reg.json
echo.

for /f "delims=" %%a in ('powershell -Command "(Get-Content p_reg.json -ErrorAction SilentlyContinue | ConvertFrom-Json).id"') do set P_ID=%%a

if "%P_ID%"=="" (
    echo [ERROR] Failed to register passenger
    pause
    goto menu
)

echo [SUCCESS] Passenger registered
echo Passenger ID: %P_ID%
echo.

echo [DATABASE CHECK] Querying User Service Database...
echo.
docker exec -i postgres-user psql -U %USER_DB_USER% -d %USER_DB_NAME% -c "SELECT id, email, full_name, phone, role, created_at FROM users WHERE id='%P_ID%';"
echo.

pause

REM Login
echo [Step 2/2] Logging in...
echo.

curl -s -X POST %BASE_URL%/sessions ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"%P_EMAIL%\",\"password\":\"%P_PASSWORD%\"}" ^
  -o p_token.json

echo [Response]
type p_token.json
echo.

for /f "delims=" %%a in ('powershell -Command "(Get-Content p_token.json -ErrorAction SilentlyContinue | ConvertFrom-Json).access_token"') do set P_TOKEN=%%a

if "%P_TOKEN%"=="" (
    echo [ERROR] Failed to login
    pause
    goto menu
)

echo [SUCCESS] Login successful
echo JWT Token: %P_TOKEN:~0,60%...
echo.

echo [DATABASE CHECK] Verify user exists in database:
echo.
docker exec -i postgres-user psql -U %USER_DB_USER% -d %USER_DB_NAME% -c "SELECT id, email, role, created_at FROM users WHERE email='%P_EMAIL%';"
echo.

echo [CHECK LOGS] Verify user-service processed registration:
echo.
docker-compose logs user-service --tail=20 | findstr /i "POST register %P_EMAIL%"
echo.

echo Press any key to return to menu...
pause >nul
goto menu

REM ===========================================================================
REM PASSENGER US2: Estimate and Create Trip
REM ===========================================================================
:passenger_us2
cls
echo.
echo ====================================================================
echo   [Passenger US2] Estimate Price and Create Trip
echo ====================================================================
echo.
echo This story demonstrates:
echo   - Price estimation (public endpoint)
echo   - Trip creation with JWT authentication
echo   - Inter-service communication (Trip -^> User, Trip -^> Driver)
echo.
echo Services involved:
echo   - Trip Service: Calculate price, create trip
echo   - User Service: Verify passenger exists
echo   - Driver Service: Find available drivers
echo.

if "%P_TOKEN%"=="" (
    echo [ERROR] Please run Passenger US1 first to get JWT token
    pause
    goto menu
)

pause

echo.
echo [Step 1/2] Estimating trip price...
echo From: UIT Campus (10.87, 106.803)
echo To: Ben Xe Mien Dong (10.815, 106.75)
echo.

curl -s -X POST %BASE_URL%/trips/estimate ^
  -H "Content-Type: application/json" ^
  -d "{\"origin\":{\"latitude\":10.87,\"longitude\":106.803},\"destination\":{\"latitude\":10.815,\"longitude\":106.75}}" ^
  -o estimate.json

echo [Response]
type estimate.json
echo.

echo [SUCCESS] Price estimated
echo.
pause

echo [Step 2/2] Creating trip with JWT authentication...
echo.

curl -s -X POST %BASE_URL%/trips ^
  -H "Content-Type: application/json" ^
  -H "Authorization: Bearer %P_TOKEN%" ^
  -d "{\"origin\":{\"latitude\":10.87,\"longitude\":106.803},\"destination\":{\"latitude\":10.815,\"longitude\":106.75}}" ^
  -o trip.json

echo [Response]
type trip.json
echo.

for /f "delims=" %%a in ('powershell -Command "(Get-Content trip.json -ErrorAction SilentlyContinue | ConvertFrom-Json).id"') do set TRIP_ID=%%a

if "%TRIP_ID%"=="" (
    echo [ERROR] Failed to create trip - check response above
    pause
    goto menu
)

echo [SUCCESS] Trip created
echo Trip ID: %TRIP_ID%
echo Status: FINDING_DRIVER
echo.

echo [DATABASE CHECK] Querying Trip Service Database...
echo.
docker exec -i postgres-trip psql -U %TRIP_DB_USER% -d %TRIP_DB_NAME% -c "SELECT id, passenger_id, status, estimated_price, origin_lat, origin_lng, destination_lat, destination_lng, created_at FROM trips WHERE id='%TRIP_ID%';"
echo.

echo ====================================================================
echo   [INTER-SERVICE COMMUNICATION CHECK]
echo ====================================================================
echo.
echo Checking if Trip Service called other services...
echo.

echo [1] Trip Service -^> User Service (verify passenger):
docker-compose logs trip-service --tail=50 | findstr /i "user-service http://user-service:8080"
echo.

echo [2] Trip Service -^> Driver Service (find drivers):
docker-compose logs trip-service --tail=50 | findstr /i "driver-service http://driver-service:8082"
echo.

echo [3] Recent Trip Service logs:
docker-compose logs trip-service --tail=10
echo.

echo Press any key to return to menu...
pause >nul
goto menu

REM ===========================================================================
REM PASSENGER US3: Track Driver Location
REM ===========================================================================
:passenger_us3
cls
echo.
echo ====================================================================
echo   [Passenger US3] Track Driver Location (Polling)
echo ====================================================================
echo.
echo This story demonstrates:
echo   - Real-time location tracking via polling
echo   - Multiple API calls to track driver movement
echo.
echo Services involved:
echo   - Trip Service: Get driver location from trip
echo   - Driver Service: Provide current driver coordinates
echo.

if "%TRIP_ID%"=="" (
    echo [ERROR] Please run Passenger US2 first to create a trip
    pause
    goto menu
)

if "%P_TOKEN%"=="" (
    echo [ERROR] Please run Passenger US1 first to get JWT token
    pause
    goto menu
)

pause

echo.
echo Polling driver location for trip: %TRIP_ID%
echo.
echo Will poll 3 times with 3-second intervals...
echo.

for /l %%i in (1,1,3) do (
    echo [Poll %%i/3] Time: !time!
    curl -s -X GET "%BASE_URL%/trips/%TRIP_ID%/driver-location" ^
      -H "Authorization: Bearer %P_TOKEN%"
    echo.
    echo.
    if %%i LSS 3 (
        echo Waiting 3 seconds...
        timeout /t 3 /nobreak >nul
        echo.
    )
)

echo [SUCCESS] Location tracking completed
echo.

echo [CHECK LOGS] Recent Trip Service activity:
docker-compose logs trip-service --tail=10
echo.

echo Press any key to return to menu...
pause >nul
goto menu

REM ===========================================================================
REM PASSENGER US4: Cancel Trip
REM ===========================================================================
:passenger_us4
cls
echo.
echo ====================================================================
echo   [Passenger US4] Cancel Trip
echo ====================================================================
echo.
echo This story demonstrates:
echo   - Passenger cancels an active trip
echo   - Trip status changes to CANCELLED
echo.
echo Services involved:
echo   - Trip Service: Update trip status
echo.

if "%TRIP_ID%"=="" (
    echo [ERROR] Please run Passenger US2 first to create a trip
    pause
    goto menu
)

if "%P_TOKEN%"=="" (
    echo [ERROR] Please run Passenger US1 first to get JWT token
    pause
    goto menu
)

pause

echo.
echo Cancelling trip: %TRIP_ID%
echo.

curl -s -X POST "%BASE_URL%/trips/%TRIP_ID%/cancel" ^
  -H "Authorization: Bearer %P_TOKEN%"

echo.
echo.
echo [SUCCESS] Trip cancelled
echo.

echo [DATABASE CHECK] Verify trip status in database:
echo.
docker exec -i postgres-trip psql -U %TRIP_DB_USER% -d %TRIP_DB_NAME% -c "SELECT id, status, cancelled_at FROM trips WHERE id='%TRIP_ID%';"
echo.

echo Creating a new trip for remaining tests...
curl -s -X POST %BASE_URL%/trips ^
  -H "Content-Type: application/json" ^
  -H "Authorization: Bearer %P_TOKEN%" ^
  -d "{\"origin\":{\"latitude\":10.87,\"longitude\":106.803},\"destination\":{\"latitude\":10.815,\"longitude\":106.75}}" ^
  -o trip2.json

for /f "delims=" %%a in ('powershell -Command "(Get-Content trip2.json -ErrorAction SilentlyContinue | ConvertFrom-Json).id"') do set TRIP_ID=%%a
echo New Trip ID: %TRIP_ID%
echo.

echo [DATABASE CHECK] All trips for this passenger:
echo.
docker exec -i postgres-trip psql -U %TRIP_DB_USER% -d %TRIP_DB_NAME% -c "SELECT id, status, cancelled_at, created_at FROM trips WHERE passenger_id='%P_ID%' ORDER BY created_at DESC LIMIT 5;"
echo.

echo [CHECK LOGS] Recent Trip Service activity:
docker-compose logs trip-service --tail=10
echo.

echo Press any key to return to menu...
pause >nul
goto menu

REM ===========================================================================
REM PASSENGER US5: Rate and View History
REM ===========================================================================
:passenger_us5
cls
echo.
echo ====================================================================
echo   [Passenger US5] Rate Trip and View History
echo ====================================================================
echo.
echo This story demonstrates:
echo   - Rating a completed trip
echo   - Viewing trip history
echo.
echo Services involved:
echo   - Trip Service: Store rating, fetch history
echo.

if "%P_ID%"=="" (
    echo [ERROR] Please run Passenger US1 first
    pause
    goto menu
)

if "%P_TOKEN%"=="" (
    echo [ERROR] Please run Passenger US1 first to get JWT token
    pause
    goto menu
)

pause

if not "%TRIP_ID%"=="" (
    echo.
    echo [Step 1/2] Rating trip (5 stars)...
    echo Trip ID: %TRIP_ID%
    echo.

    curl -s -X POST "%BASE_URL%/trips/%TRIP_ID%/rating" ^
      -H "Content-Type: application/json" ^
      -H "Authorization: Bearer %P_TOKEN%" ^
      -d "{\"rating\":5,\"comment\":\"Excellent driver, very professional!\"}"

    echo.
    echo.
    echo [SUCCESS] Rating submitted
    echo.
    pause
)

echo [Step 2/2] Fetching trip history...
echo Passenger ID: %P_ID%
echo.

curl -s -X GET "%BASE_URL%/trips/passenger/%P_ID%/history?page=1&limit=10" ^
  -H "Authorization: Bearer %P_TOKEN%"

echo.
echo.
echo [SUCCESS] History retrieved
echo.

echo [DATABASE CHECK] Trip history with ratings in database:
echo.
docker exec -i postgres-trip psql -U %TRIP_DB_USER% -d %TRIP_DB_NAME% -c "SELECT id, status, rating, rating_comment, estimated_price, created_at FROM trips WHERE passenger_id='%P_ID%' ORDER BY created_at DESC LIMIT 5;"
echo.

echo [CHECK LOGS] Recent Trip Service activity:
docker-compose logs trip-service --tail=10
echo.

echo Press any key to return to menu...
pause >nul
goto menu

REM ===========================================================================
REM DRIVER US1: Register and Login
REM ===========================================================================
:driver_us1
cls
echo.
echo ====================================================================
echo   [Driver US1] Register with Vehicle Info and Login
echo ====================================================================
echo.
echo This story demonstrates:
echo   - Driver registration with vehicle information
echo   - JWT authentication for drivers
echo.
echo Services involved:
echo   - User Service: Register driver with vehicle data
echo   - Auth Service: Generate JWT token
echo.
pause

REM Register
set D_EMAIL=driver_%RANDOM%@uit.edu.vn
set D_PASSWORD=Driver123!

echo.
echo [Step 1/2] Registering driver...
echo Email: %D_EMAIL%
echo Password: %D_PASSWORD%
echo Vehicle: Toyota Vios (51G-123.45)
echo.

curl -s -X POST %BASE_URL%/users ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"%D_EMAIL%\",\"password\":\"%D_PASSWORD%\",\"fullName\":\"Tran Van B\",\"phone\":\"0908765432\",\"role\":\"DRIVER\",\"vehicleInfo\":{\"plate_number\":\"51G-123.45\",\"model\":\"Toyota Vios\",\"type\":\"4_SEATS\"}}" ^
  -o d_reg.json

echo [Response]
type d_reg.json
echo.

for /f "delims=" %%a in ('powershell -Command "(Get-Content d_reg.json -ErrorAction SilentlyContinue | ConvertFrom-Json).id"') do set D_ID=%%a

if "%D_ID%"=="" (
    echo [ERROR] Failed to register driver
    pause
    goto menu
)

echo [SUCCESS] Driver registered
echo Driver ID: %D_ID%
echo.

echo [DATABASE CHECK] Querying User Service Database for Driver:
echo.
docker exec -i postgres-user psql -U %USER_DB_USER% -d %USER_DB_NAME% -c "SELECT id, email, full_name, phone, role, vehicle_plate_number, vehicle_model, vehicle_type, created_at FROM users WHERE id='%D_ID%';"
echo.

pause

REM Login
echo [Step 2/2] Logging in driver...
echo.

curl -s -X POST %BASE_URL%/sessions ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"%D_EMAIL%\",\"password\":\"%D_PASSWORD%\"}" ^
  -o d_token.json

echo [Response]
type d_token.json
echo.

for /f "delims=" %%a in ('powershell -Command "(Get-Content d_token.json -ErrorAction SilentlyContinue | ConvertFrom-Json).access_token"') do set D_TOKEN=%%a

if "%D_TOKEN%"=="" (
    echo [ERROR] Failed to login
    pause
    goto menu
)

echo [SUCCESS] Login successful
echo JWT Token: %D_TOKEN:~0,60%...
echo.

echo [CHECK LOGS] Verify user-service processed registration:
docker-compose logs user-service --tail=20 | findstr /i "POST register %D_EMAIL%"
echo.

echo Press any key to return to menu...
pause >nul
goto menu

REM ===========================================================================
REM DRIVER US2: Set Status ONLINE
REM ===========================================================================
:driver_us2
cls
echo.
echo ====================================================================
echo   [Driver US2] Set Status to ONLINE
echo ====================================================================
echo.
echo This story demonstrates:
echo   - Driver changes status to accept trips
echo   - Driver location is registered in Redis
echo.
echo Services involved:
echo   - Driver Service: Update driver status, store location in Redis
echo.

if "%D_ID%"=="" (
    echo [ERROR] Please run Driver US1 first
    pause
    goto menu
)

if "%D_TOKEN%"=="" (
    echo [ERROR] Please run Driver US1 first to get JWT token
    pause
    goto menu
)

pause

echo.
echo Setting driver status to ONLINE...
echo Driver ID: %D_ID%
echo.

curl -s -X PUT "%BASE_URL%/drivers/%D_ID%/status" ^
  -H "Content-Type: application/json" ^
  -H "Authorization: Bearer %D_TOKEN%" ^
  -d "{\"status\":\"ONLINE\"}"

echo.
echo.
echo [SUCCESS] Driver status changed to ONLINE
echo.

echo [DATABASE CHECK] Driver location in Redis (via Driver Service):
echo.
docker exec -i redis-driver redis-cli GET "driver:%D_ID%:status"
echo.
echo Driver location data:
docker exec -i redis-driver redis-cli GEOSEARCH drivers FROMLONLAT 106.803 10.87 BYRADIUS 10000 m WITHDIST WITHCOORD
echo.

echo [CHECK LOGS] Driver Service activity:
docker-compose logs driver-service --tail=10
echo.

echo Press any key to return to menu...
pause >nul
goto menu

REM ===========================================================================
REM DRIVER US3: View and Accept Trip
REM ===========================================================================
:driver_us3
cls
echo.
echo ====================================================================
echo   [Driver US3] View Available Trips and Accept
echo ====================================================================
echo.
echo This story demonstrates:
echo   - Driver views available trips nearby
echo   - Driver accepts a trip
echo   - Trip status changes to DRIVER_ASSIGNED
echo.
echo Services involved:
echo   - Trip Service: List available trips, assign driver
echo   - Driver Service: Check driver availability
echo.

if "%D_TOKEN%"=="" (
    echo [ERROR] Please run Driver US1 first to get JWT token
    pause
    goto menu
)

pause

echo.
echo [Step 1/2] Fetching available trips (radius: 5000m)...
echo.

curl -s -X GET "%BASE_URL%/trips/available?radius=5000" ^
  -H "Authorization: Bearer %D_TOKEN%"

echo.
echo.
pause

if "%TRIP_ID%"=="" (
    echo [ERROR] No trip available. Please run Passenger US2 first.
    pause
    goto menu
)

echo [Step 2/2] Accepting trip...
echo Trip ID: %TRIP_ID%
echo.

curl -s -X POST "%BASE_URL%/trips/%TRIP_ID%/accept" ^
  -H "Authorization: Bearer %D_TOKEN%"

echo.
echo.
echo [SUCCESS] Trip accepted
echo.

echo [DATABASE CHECK] Trip updated with driver assignment:
echo.
docker exec -i postgres-trip psql -U %TRIP_DB_USER% -d %TRIP_DB_NAME% -c "SELECT id, passenger_id, driver_id, status, accepted_at FROM trips WHERE id='%TRIP_ID%';"
echo.

echo [CHECK LOGS] Trip Service activity:
docker-compose logs trip-service --tail=10
echo.

echo Press any key to return to menu...
pause >nul
goto menu

REM ===========================================================================
REM DRIVER US4: Update Location and Start Trip
REM ===========================================================================
:driver_us4
cls
echo.
echo ====================================================================
echo   [Driver US4] Update Location and Start Trip
echo ====================================================================
echo.
echo This story demonstrates:
echo   - Real-time driver location updates
echo   - Driver starts trip after picking up passenger
echo   - Trip status changes to IN_PROGRESS
echo.
echo Services involved:
echo   - Driver Service: Update location in Redis
echo   - Trip Service: Change trip status
echo.

if "%D_ID%"=="" (
    echo [ERROR] Please run Driver US1 first
    pause
    goto menu
)

if "%D_TOKEN%"=="" (
    echo [ERROR] Please run Driver US1 first to get JWT token
    pause
    goto menu
)

pause

echo.
echo [Step 1/2] Updating driver location (3 times)...
echo Simulating driver moving to pickup point...
echo.

set LAT=10.865
set LNG=106.8

for /l %%i in (1,1,3) do (
    echo [Update %%i/3] Location: (!LAT!, !LNG!) at !time!
    
    curl -s -X PUT "%BASE_URL%/drivers/%D_ID%/location" ^
      -H "Content-Type: application/json" ^
      -H "Authorization: Bearer %D_TOKEN%" ^
      -d "{\"latitude\":!LAT!,\"longitude\":!LNG!}"
    echo.
    
    if %%i EQU 1 (
        set LAT=10.867
        set LNG=106.801
    )
    if %%i EQU 2 (
        set LAT=10.869
        set LNG=106.802
    )
    
    if %%i LSS 3 (
        echo Waiting 2 seconds...
        timeout /t 2 /nobreak >nul
    )
)

echo.
echo [SUCCESS] Location updates completed
echo.

echo [CHECK LOGS] Driver Service activity:
docker-compose logs driver-service --tail=10
echo.
pause

if "%TRIP_ID%"=="" (
    echo [ERROR] No trip to start. Please run Driver US3 first.
    pause
    goto menu
)

echo [Step 2/2] Starting trip...
echo Trip ID: %TRIP_ID%
echo.

curl -s -X POST "%BASE_URL%/trips/%TRIP_ID%/start" ^
  -H "Authorization: Bearer %D_TOKEN%"

echo.
echo.
echo [SUCCESS] Trip started - Status: IN_PROGRESS
echo.

echo [DATABASE CHECK] Trip status and times in database:
echo.
docker exec -i postgres-trip psql -U %TRIP_DB_USER% -d %TRIP_DB_NAME% -c "SELECT id, status, accepted_at, started_at FROM trips WHERE id='%TRIP_ID%';"
echo.

echo [CHECK LOGS] Trip Service activity:
docker-compose logs trip-service --tail=10
echo.

echo Press any key to return to menu...
pause >nul
goto menu

REM ===========================================================================
REM DRIVER US5: Complete Trip and View Earnings
REM ===========================================================================
:driver_us5
cls
echo.
echo ====================================================================
echo   [Driver US5] Complete Trip and View Earnings
echo ====================================================================
echo.
echo This story demonstrates:
echo   - Driver completes trip
echo   - Trip status changes to COMPLETED
echo   - Driver views earnings statistics
echo.
echo Services involved:
echo   - Trip Service: Update status, calculate earnings
echo.

if "%D_ID%"=="" (
    echo [ERROR] Please run Driver US1 first
    pause
    goto menu
)

if "%D_TOKEN%"=="" (
    echo [ERROR] Please run Driver US1 first to get JWT token
    pause
    goto menu
)

pause

if not "%TRIP_ID%"=="" (
    echo.
    echo [Step 1/3] Completing trip...
    echo Trip ID: %TRIP_ID%
    echo.

    curl -s -X POST "%BASE_URL%/trips/%TRIP_ID%/complete" ^
      -H "Authorization: Bearer %D_TOKEN%"

    echo.
    echo.
    echo [SUCCESS] Trip completed
    echo.
    pause
)

echo [Step 2/3] Fetching driver history...
echo Driver ID: %D_ID%
echo.

curl -s -X GET "%BASE_URL%/trips/driver/%D_ID%/history?page=1&limit=10" ^
  -H "Authorization: Bearer %D_TOKEN%"

echo.
echo.
pause

echo [Step 3/3] Fetching today's earnings...
echo.

curl -s -X GET "%BASE_URL%/trips/driver/%D_ID%/earnings?period=today" ^
  -H "Authorization: Bearer %D_TOKEN%"

echo.
echo.
echo [SUCCESS] Earnings retrieved
echo.

echo [DATABASE CHECK] Completed trips and earnings in database:
echo.
docker exec -i postgres-trip psql -U %TRIP_DB_USER% -d %TRIP_DB_NAME% -c "SELECT id, driver_id, status, estimated_price, final_price, started_at, completed_at FROM trips WHERE driver_id='%D_ID%' AND status='COMPLETED' ORDER BY completed_at DESC LIMIT 5;"
echo.

echo [DATABASE CHECK] Total earnings calculation:
echo.
docker exec -i postgres-trip psql -U %TRIP_DB_USER% -d %TRIP_DB_NAME% -c "SELECT COUNT(*) as total_trips, SUM(final_price) as total_earnings, AVG(rating) as avg_rating FROM trips WHERE driver_id='%D_ID%' AND status='COMPLETED';"
echo.

echo [CHECK LOGS] Trip Service activity:
docker-compose logs trip-service --tail=10
echo.

echo Press any key to return to menu...
pause >nul
goto menu

REM ===========================================================================
REM CHECK INTER-SERVICE COMMUNICATION LOGS
REM ===========================================================================
:check_logs
cls
echo.
echo ====================================================================
echo   Inter-Service Communication Logs
echo ====================================================================
echo.
echo Analyzing logs to verify services are calling each other...
echo.
pause

echo [1] Trip Service -^> User Service (verify passengers/drivers):
echo ---------------------------------------------------------------
docker-compose logs trip-service --tail=100 | findstr /i "user-service http://user-service:8080 GET POST"
echo.
echo.

echo [2] Trip Service -^> Driver Service (find drivers, locations):
echo ---------------------------------------------------------------
docker-compose logs trip-service --tail=100 | findstr /i "driver-service http://driver-service:8082 GET POST"
echo.
echo.

echo [3] All HTTP calls from Trip Service:
echo ---------------------------------------------------------------
docker-compose logs trip-service --tail=50 | findstr /i "http://"
echo.
echo.

echo [4] Recent User Service activity:
echo ---------------------------------------------------------------
docker-compose logs user-service --tail=20
echo.
echo.

echo [5] Recent Driver Service activity:
echo ---------------------------------------------------------------
docker-compose logs driver-service --tail=20
echo.
echo.

echo Press any key to return to menu...
pause >nul
goto menu

REM ===========================================================================
REM VIEW ALL SERVICE LOGS
REM ===========================================================================
:view_all_logs
cls
echo.
echo ====================================================================
echo   All Service Logs (Last 30 lines each)
echo ====================================================================
echo.
pause

echo [User Service]
echo ---------------------------------------------------------------
docker-compose logs user-service --tail=30
echo.
echo.

echo [Trip Service]
echo ---------------------------------------------------------------
docker-compose logs trip-service --tail=30
echo.
echo.

echo [Driver Service]
echo ---------------------------------------------------------------
docker-compose logs driver-service --tail=30
echo.
echo.

echo [Auth Service]
echo ---------------------------------------------------------------
docker-compose logs auth-service --tail=30
echo.
echo.

echo [Nginx Gateway]
echo ---------------------------------------------------------------
docker-compose logs nginx --tail=30
echo.
echo.

echo Press any key to return to menu...
pause >nul
goto menu

REM ===========================================================================
REM SHOW CURRENT TEST DATA
REM ===========================================================================
:show_data
cls
echo.
echo ====================================================================
echo   Current Test Data
echo ====================================================================
echo.
echo PASSENGER:
echo   Email: %P_EMAIL%
echo   Password: %P_PASSWORD%
echo   ID: %P_ID%
echo   Token: %P_TOKEN:~0,60%...
echo.
echo DRIVER:
echo   Email: %D_EMAIL%
echo   Password: %D_PASSWORD%
echo   ID: %D_ID%
echo   Token: %D_TOKEN:~0,60%...
echo.
echo TRIP:
echo   ID: %TRIP_ID%
echo.
echo Press any key to return to menu...
pause >nul
goto menu

REM ===========================================================================
REM RUN ALL STORIES AUTOMATICALLY
REM ===========================================================================
:run_all
cls
echo.
echo ====================================================================
echo   Run All Stories Automatically
echo ====================================================================
echo.
echo This will run all 10 user stories sequentially.
echo Each story will have a short pause between steps.
echo.
echo Press any key to start or Ctrl+C to cancel...
pause >nul

call :passenger_us1_auto
call :passenger_us2_auto
call :passenger_us3_auto
call :passenger_us4_auto
call :passenger_us5_auto
call :driver_us1_auto
call :driver_us2_auto
call :driver_us3_auto
call :driver_us4_auto
call :driver_us5_auto

echo.
echo ====================================================================
echo   ALL STORIES COMPLETED
echo ====================================================================
echo.
call :check_logs
pause
goto menu

:passenger_us1_auto
echo.
echo [Passenger US1] Register and Login
set P_EMAIL=passenger_%RANDOM%@uit.edu.vn
set P_PASSWORD=Pass123!
curl -s -X POST %BASE_URL%/users -H "Content-Type: application/json" -d "{\"email\":\"%P_EMAIL%\",\"password\":\"%P_PASSWORD%\",\"fullName\":\"Nguyen Van A\",\"phone\":\"0909123456\",\"role\":\"PASSENGER\"}" -o p_reg.json
for /f "delims=" %%a in ('powershell -Command "(Get-Content p_reg.json -ErrorAction SilentlyContinue | ConvertFrom-Json).id"') do set P_ID=%%a
curl -s -X POST %BASE_URL%/sessions -H "Content-Type: application/json" -d "{\"email\":\"%P_EMAIL%\",\"password\":\"%P_PASSWORD%\"}" -o p_token.json
for /f "delims=" %%a in ('powershell -Command "(Get-Content p_token.json -ErrorAction SilentlyContinue | ConvertFrom-Json).access_token"') do set P_TOKEN=%%a
echo [OK] Passenger registered and logged in
timeout /t 2 /nobreak >nul
goto :eof

:passenger_us2_auto
echo.
echo [Passenger US2] Estimate and Create Trip
curl -s -X POST %BASE_URL%/trips/estimate -H "Content-Type: application/json" -d "{\"origin\":{\"latitude\":10.87,\"longitude\":106.803},\"destination\":{\"latitude\":10.815,\"longitude\":106.75}}" -o estimate.json
curl -s -X POST %BASE_URL%/trips -H "Content-Type: application/json" -H "Authorization: Bearer %P_TOKEN%" -d "{\"origin\":{\"latitude\":10.87,\"longitude\":106.803},\"destination\":{\"latitude\":10.815,\"longitude\":106.75}}" -o trip.json
for /f "delims=" %%a in ('powershell -Command "(Get-Content trip.json -ErrorAction SilentlyContinue | ConvertFrom-Json).id"') do set TRIP_ID=%%a
echo [OK] Trip created: %TRIP_ID%
timeout /t 2 /nobreak >nul
goto :eof

:passenger_us3_auto
echo.
echo [Passenger US3] Track Driver Location
curl -s -X GET "%BASE_URL%/trips/%TRIP_ID%/driver-location" -H "Authorization: Bearer %P_TOKEN%" >nul
echo [OK] Location tracked
timeout /t 1 /nobreak >nul
goto :eof

:passenger_us4_auto
echo.
echo [Passenger US4] Cancel Trip
curl -s -X POST "%BASE_URL%/trips/%TRIP_ID%/cancel" -H "Authorization: Bearer %P_TOKEN%" >nul
curl -s -X POST %BASE_URL%/trips -H "Content-Type: application/json" -H "Authorization: Bearer %P_TOKEN%" -d "{\"origin\":{\"latitude\":10.87,\"longitude\":106.803},\"destination\":{\"latitude\":10.815,\"longitude\":106.75}}" -o trip2.json
for /f "delims=" %%a in ('powershell -Command "(Get-Content trip2.json -ErrorAction SilentlyContinue | ConvertFrom-Json).id"') do set TRIP_ID=%%a
echo [OK] Trip cancelled and new trip created
timeout /t 1 /nobreak >nul
goto :eof

:passenger_us5_auto
echo.
echo [Passenger US5] Rate and View History
curl -s -X POST "%BASE_URL%/trips/%TRIP_ID%/rating" -H "Content-Type: application/json" -H "Authorization: Bearer %P_TOKEN%" -d "{\"rating\":5,\"comment\":\"Great!\"}" >nul
curl -s -X GET "%BASE_URL%/trips/passenger/%P_ID%/history?page=1&limit=10" -H "Authorization: Bearer %P_TOKEN%" >nul
echo [OK] Rating submitted and history viewed
timeout /t 1 /nobreak >nul
goto :eof

:driver_us1_auto
echo.
echo [Driver US1] Register and Login
set D_EMAIL=driver_%RANDOM%@uit.edu.vn
set D_PASSWORD=Driver123!
curl -s -X POST %BASE_URL%/users -H "Content-Type: application/json" -d "{\"email\":\"%D_EMAIL%\",\"password\":\"%D_PASSWORD%\",\"fullName\":\"Tran Van B\",\"phone\":\"0908765432\",\"role\":\"DRIVER\",\"vehicleInfo\":{\"plate_number\":\"51G-123.45\",\"model\":\"Toyota Vios\",\"type\":\"4_SEATS\"}}" -o d_reg.json
for /f "delims=" %%a in ('powershell -Command "(Get-Content d_reg.json -ErrorAction SilentlyContinue | ConvertFrom-Json).id"') do set D_ID=%%a
curl -s -X POST %BASE_URL%/sessions -H "Content-Type: application/json" -d "{\"email\":\"%D_EMAIL%\",\"password\":\"%D_PASSWORD%\"}" -o d_token.json
for /f "delims=" %%a in ('powershell -Command "(Get-Content d_token.json -ErrorAction SilentlyContinue | ConvertFrom-Json).access_token"') do set D_TOKEN=%%a
echo [OK] Driver registered and logged in
timeout /t 2 /nobreak >nul
goto :eof

:driver_us2_auto
echo.
echo [Driver US2] Set Status ONLINE
curl -s -X PUT "%BASE_URL%/drivers/%D_ID%/status" -H "Content-Type: application/json" -H "Authorization: Bearer %D_TOKEN%" -d "{\"status\":\"ONLINE\"}" >nul
echo [OK] Driver status set to ONLINE
timeout /t 1 /nobreak >nul
goto :eof

:driver_us3_auto
echo.
echo [Driver US3] View and Accept Trip
curl -s -X GET "%BASE_URL%/trips/available?radius=5000" -H "Authorization: Bearer %D_TOKEN%" >nul
curl -s -X POST "%BASE_URL%/trips/%TRIP_ID%/accept" -H "Authorization: Bearer %D_TOKEN%" >nul
echo [OK] Trip accepted
timeout /t 1 /nobreak >nul
goto :eof

:driver_us4_auto
echo.
echo [Driver US4] Update Location and Start Trip
curl -s -X PUT "%BASE_URL%/drivers/%D_ID%/location" -H "Content-Type: application/json" -H "Authorization: Bearer %D_TOKEN%" -d "{\"latitude\":10.87,\"longitude\":106.8}" >nul
curl -s -X POST "%BASE_URL%/trips/%TRIP_ID%/start" -H "Authorization: Bearer %D_TOKEN%" >nul
echo [OK] Location updated and trip started
timeout /t 1 /nobreak >nul
goto :eof

:driver_us5_auto
echo.
echo [Driver US5] Complete Trip and View Earnings
curl -s -X POST "%BASE_URL%/trips/%TRIP_ID%/complete" -H "Authorization: Bearer %D_TOKEN%" >nul
curl -s -X GET "%BASE_URL%/trips/driver/%D_ID%/history?page=1&limit=10" -H "Authorization: Bearer %D_TOKEN%" >nul
curl -s -X GET "%BASE_URL%/trips/driver/%D_ID%/earnings?period=today" -H "Authorization: Bearer %D_TOKEN%" >nul
echo [OK] Trip completed and earnings viewed
timeout /t 1 /nobreak >nul
goto :eof

REM ===========================================================================
REM CLEANUP AND EXIT
REM ===========================================================================
:cleanup
cls
echo.
echo ====================================================================
echo   Cleanup
echo ====================================================================
echo.
echo Cleaning up temporary files...
echo.

del p_reg.json 2>nul
del p_token.json 2>nul
del d_reg.json 2>nul
del d_token.json 2>nul
del estimate.json 2>nul
del trip.json 2>nul
del trip2.json 2>nul

echo [OK] Temporary files deleted
echo.
echo Do you want to view final inter-service communication logs? (Y/N)
set /p view_final="Choice: "

if /i "%view_final%"=="Y" call :check_logs

echo.
echo ====================================================================
echo   Demo Complete
echo ====================================================================
echo.
echo Thank you for using UIT-Go Interactive Demo!
echo.
pause
exit /b 0
