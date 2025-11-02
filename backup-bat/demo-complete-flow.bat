@echo off
chcp 65001 >nul
REM ===========================================================================
REM Script: demo-complete-flow.bat
REM Purpose: Demo 10 User Stories - Passenger (5) + Driver (5)
REM ===========================================================================

setlocal enabledelayedexpansion

echo.
echo ========================================
echo   UIT-Go - Complete Flow Demo
echo   Testing All 10 User Stories
echo ========================================
echo.

REM ===========================================================================
REM PART I: PASSENGER FLOW - 5 USER STORIES
REM ===========================================================================

echo.
echo ====================================================================
echo   PART I: PASSENGER FLOW (5 User Stories)
echo ====================================================================
echo.

REM US1: Register passenger account
echo [Passenger US1] Register Account
echo ====================================================================
echo.

set PASSENGER_EMAIL=passenger_%RANDOM%@uit.edu.vn
set PASSENGER_PASSWORD=Pass123!

echo ^> Creating passenger account...
echo ^> Email: %PASSENGER_EMAIL%
echo.

curl -X POST http://localhost:8088/api/users ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"%PASSENGER_EMAIL%\",\"password\":\"%PASSENGER_PASSWORD%\",\"fullName\":\"Nguyen Van A\",\"phone\":\"0909123456\",\"role\":\"PASSENGER\"}" ^
  -o passenger_register.json ^
  -w "\nHTTP %%{http_code} - Time: %%{time_total}s\n"

echo.
echo ^[Response^]
type passenger_register.json
echo.
echo.
timeout /t 1 /nobreak > nul

REM US1: Login and get JWT token
echo [Passenger US1] Login
echo ====================================================================
echo.

echo ^> Logging in...
curl -X POST http://localhost:8088/api/sessions ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"%PASSENGER_EMAIL%\",\"password\":\"%PASSENGER_PASSWORD%\"}" ^
  -o passenger_token.json ^
  -w "\nHTTP %%{http_code} - Time: %%{time_total}s\n"

REM Extract token from JSON
for /f "tokens=2 delims=:," %%a in (passenger_token.json) do (
    set PASSENGER_TOKEN=%%a
    goto :passenger_token_parsed
)
:passenger_token_parsed
set PASSENGER_TOKEN=%PASSENGER_TOKEN:"=%
set PASSENGER_TOKEN=%PASSENGER_TOKEN: =%

echo.
echo ^[Response^]
type passenger_token.json
echo.
echo ^[Token^] %PASSENGER_TOKEN:~0,50%...
echo.
timeout /t 1 /nobreak > nul

REM US2: Estimate trip price
echo [Passenger US2] Estimate Price
echo ====================================================================
echo.
echo ^> Origin: UIT Campus (10.8700, 106.8030)
echo ^> Destination: Ben Xe Mien Dong (10.8150, 106.7500)
echo.

curl -X POST http://localhost:8088/api/trips/estimate ^
  -H "Content-Type: application/json" ^
  -d "{\"origin\":{\"latitude\":10.8700,\"longitude\":106.8030},\"destination\":{\"latitude\":10.8150,\"longitude\":106.7500}}" ^
  -o trip_estimate.json ^
  -w "\nHTTP %%{http_code} - Time: %%{time_total}s\n"

echo.
echo ^[Response^]
type trip_estimate.json
echo.
echo.
timeout /t 1 /nobreak > nul

REM US2: Create trip
echo [Passenger US2] Create Trip
echo ====================================================================
echo.

echo ^> Creating trip with JWT authentication...
curl -X POST http://localhost:8088/api/trips ^
  -H "Content-Type: application/json" ^
  -H "Authorization: Bearer %PASSENGER_TOKEN%" ^
  -d "{\"origin\":{\"latitude\":10.8700,\"longitude\":106.8030},\"destination\":{\"latitude\":10.8150,\"longitude\":106.7500}}" ^
  -o trip_created.json ^
  -w "\nHTTP %%{http_code} - Time: %%{time_total}s\n"

REM Extract trip ID
for /f "tokens=2 delims=:," %%a in ('findstr /c:"\"id\"" trip_created.json') do (
    set TRIP_ID=%%a
    goto :trip_id_parsed
)
:trip_id_parsed
set TRIP_ID=%TRIP_ID:"=%
set TRIP_ID=%TRIP_ID: =%

echo.
echo ^[Response^]
type trip_created.json
echo.
echo ^[Trip ID^] %TRIP_ID%
echo.
timeout /t 1 /nobreak > nul

REM ----------------------------------------------------------------------------
REM Hành khách US3: Theo dõi vị trí tài xế (polling mỗi 5 giây)
REM ----------------------------------------------------------------------------
echo.
echo [Hành khách US3] Theo dõi vị trí tài xế
echo ================================================
echo.
echo Đang lấy vị trí tài xế (mô phỏng polling mỗi 5 giây)...
echo.

REM Poll 3 lần để demo
for /l %%i in (1,1,3) do (
    echo [Poll %%i/3] Lấy vị trí tài xế lúc !time!
    curl -X GET "http://localhost:8088/api/trips/%TRIP_ID%/driver-location" ^
      -H "Authorization: Bearer %PASSENGER_TOKEN%" ^
      -s
    echo.
    echo.
    timeout /t 5 /nobreak > nul
)

echo ✓ Đã theo dõi vị trí tài xế
echo.
timeout /t 2 /nobreak > nul

REM ----------------------------------------------------------------------------
REM Hành khách US4: Hủy chuyến đi
REM ----------------------------------------------------------------------------
echo.
echo [Hành khách US4] Hủy chuyến đi
echo ================================================
echo.
echo Hành khách quyết định hủy chuyến đi...
echo.

curl -X POST "http://localhost:8088/api/trips/%TRIP_ID%/cancel" ^
  -H "Authorization: Bearer %PASSENGER_TOKEN%" ^
  -s -w "\nHTTP Status: %%{http_code}\n"

echo.
echo ✓ Chuyến đi đã được hủy
echo.
timeout /t 2 /nobreak > nul

REM Tạo trip mới để test tiếp flow complete + rating
echo.
echo [Setup] Tạo chuyến đi mới để test flow hoàn thành
echo.

curl -X POST http://localhost:8088/api/trips ^
  -H "Content-Type: application/json" ^
  -H "Authorization: Bearer %PASSENGER_TOKEN%" ^
  -d "{\"origin\":{\"latitude\":10.8700,\"longitude\":106.8030},\"destination\":{\"latitude\":10.8150,\"longitude\":106.7500}}" ^
  -o trip_created2.json ^
  -s > nul

for /f "tokens=2 delims=:," %%a in ('findstr /c:"\"id\"" trip_created2.json') do (
    set TRIP_ID=%%a
    goto :trip_id_parsed2
)
:trip_id_parsed2
set TRIP_ID=%TRIP_ID:"=%
set TRIP_ID=%TRIP_ID: =%

echo New Trip ID: %TRIP_ID%
echo.

REM ----------------------------------------------------------------------------
REM Hành khách US5: Đánh giá chuyến đi sau khi hoàn thành
REM ----------------------------------------------------------------------------
echo.
echo [Hành khách US5] Đánh giá chuyến đi
echo ================================================
echo.
echo (Giả sử chuyến đi đã hoàn thành)
echo Hành khách đánh giá tài xế 5 sao...
echo.

curl -X POST "http://localhost:8088/api/trips/%TRIP_ID%/rating" ^
  -H "Content-Type: application/json" ^
  -H "Authorization: Bearer %PASSENGER_TOKEN%" ^
  -d "{\"rating\":5,\"comment\":\"Tài xế lái xe rất tốt, thân thiện!\"}" ^
  -s -w "\nHTTP Status: %%{http_code}\n"

echo.
echo ✓ Đã đánh giá chuyến đi
echo.
timeout /t 2 /nobreak > nul

REM ----------------------------------------------------------------------------
REM Hành khách US5 (cont): Xem lịch sử chuyến đi
REM ----------------------------------------------------------------------------
echo.
echo [Hành khách US5-History] Xem lịch sử chuyến đi
echo ================================================
echo.

REM Get passenger ID from token response
for /f "tokens=2 delims=:," %%a in ('findstr /c:"\"id\"" passenger_register.json') do (
    set PASSENGER_ID=%%a
    goto :passenger_id_parsed
)
:passenger_id_parsed
set PASSENGER_ID=%PASSENGER_ID:"=%
set PASSENGER_ID=%PASSENGER_ID: =%

echo Lấy lịch sử chuyến đi của hành khách...
echo.

curl -X GET "http://localhost:8088/api/trips/passenger/%PASSENGER_ID%/history?page=1&limit=10" ^
  -H "Authorization: Bearer %PASSENGER_TOKEN%" ^
  -s

echo.
echo.
echo ✓ Đã xem lịch sử chuyến đi
echo.
timeout /t 2 /nobreak > nul

REM ============================================================================
REM PHẦN II: TÀI XẾ (DRIVER) - 5 USER STORIES
REM ============================================================================

echo.
echo ╔════════════════════════════════════════════════════════════════╗
echo ║  PHẦN II: TÀI XẾ FLOW (5 User Stories)                        ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.

REM ----------------------------------------------------------------------------
REM Tài xế US1: Đăng ký tài khoản với thông tin xe
REM ----------------------------------------------------------------------------
echo [Tài xế US1] Đăng ký tài khoản tài xế
echo ================================================
echo.

set DRIVER_EMAIL=driver_%RANDOM%@uit.edu.vn
set DRIVER_PASSWORD=Driver123!

echo Đang tạo tài khoản tài xế với thông tin xe...
echo Email: %DRIVER_EMAIL%
echo.

curl -X POST http://localhost:8088/api/users ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"%DRIVER_EMAIL%\",\"password\":\"%DRIVER_PASSWORD%\",\"fullName\":\"Tran Van B\",\"phone\":\"0908765432\",\"role\":\"DRIVER\",\"vehicleInfo\":{\"plate_number\":\"51G-123.45\",\"model\":\"Toyota Vios\",\"type\":\"4_SEATS\"}}" ^
  -o driver_register.json ^
  -s -w "\nHTTP Status: %%{http_code}\n"

echo.
echo ✓ Tài xế đã đăng ký thành công với thông tin xe
type driver_register.json
echo.
timeout /t 2 /nobreak > nul

REM Extract driver ID
for /f "tokens=2 delims=:," %%a in ('findstr /c:"\"id\"" driver_register.json') do (
    set DRIVER_ID=%%a
    goto :driver_id_parsed
)
:driver_id_parsed
set DRIVER_ID=%DRIVER_ID:"=%
set DRIVER_ID=%DRIVER_ID: =%

echo Driver ID: %DRIVER_ID%
echo.

REM ----------------------------------------------------------------------------
REM Tài xế US1 (cont): Đăng nhập
REM ----------------------------------------------------------------------------
echo.
echo [Tài xế US1-Login] Đăng nhập tài xế
echo ================================================
echo.

curl -X POST http://localhost:8088/api/sessions ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"%DRIVER_EMAIL%\",\"password\":\"%DRIVER_PASSWORD%\"}" ^
  -o driver_token.json ^
  -s -w "\nHTTP Status: %%{http_code}\n"

for /f "tokens=2 delims=:," %%a in (driver_token.json) do (
    set DRIVER_TOKEN=%%a
    goto :driver_token_parsed
)
:driver_token_parsed
set DRIVER_TOKEN=%DRIVER_TOKEN:"=%
set DRIVER_TOKEN=%DRIVER_TOKEN: =%

echo.
echo ✓ Tài xế đăng nhập thành công, JWT token: %DRIVER_TOKEN:~0,50%...
echo.
timeout /t 2 /nobreak > nul

REM ----------------------------------------------------------------------------
REM Tài xế US2: Bật trạng thái "Sẵn sàng nhận khách" (ONLINE)
REM ----------------------------------------------------------------------------
echo.
echo [Tài xế US2] Bật trạng thái Sẵn sàng
echo ================================================
echo.

curl -X PUT "http://localhost:8088/api/drivers/%DRIVER_ID%/status" ^
  -H "Content-Type: application/json" ^
  -H "Authorization: Bearer %DRIVER_TOKEN%" ^
  -d "{\"status\":\"ONLINE\"}" ^
  -s -w "\nHTTP Status: %%{http_code}\n"

echo.
echo ✓ Tài xế đã bật trạng thái ONLINE
echo.
timeout /t 2 /nobreak > nul

REM ----------------------------------------------------------------------------
REM Tài xế US3: Xem danh sách chuyến đi khả dụng
REM ----------------------------------------------------------------------------
echo.
echo [Tài xế US3] Xem danh sách chuyến đi khả dụng
echo ================================================
echo.

curl -X GET "http://localhost:8088/api/trips/available?radius=5000" ^
  -H "Authorization: Bearer %DRIVER_TOKEN%" ^
  -s

echo.
echo.
echo ✓ Đã xem danh sách chuyến đi khả dụng
echo.
timeout /t 2 /nobreak > nul

REM ----------------------------------------------------------------------------
REM Tài xế US3 (cont): Chấp nhận chuyến đi
REM ----------------------------------------------------------------------------
echo.
echo [Tài xế US3-Accept] Chấp nhận chuyến đi
echo ================================================
echo.
echo Tài xế chấp nhận chuyến đi ID: %TRIP_ID%
echo.

curl -X POST "http://localhost:8088/api/trips/%TRIP_ID%/accept" ^
  -H "Authorization: Bearer %DRIVER_TOKEN%" ^
  -s -w "\nHTTP Status: %%{http_code}\n"

echo.
echo ✓ Tài xế đã chấp nhận chuyến đi
echo.
timeout /t 2 /nobreak > nul

REM ----------------------------------------------------------------------------
REM Tài xế US4: Cập nhật vị trí theo thời gian thực
REM ----------------------------------------------------------------------------
echo.
echo [Tài xế US4] Cập nhật vị trí theo thời gian thực
echo ================================================
echo.
echo Mô phỏng tài xế di chuyển đến điểm đón...
echo.

REM Update location 3 lần để demo
set LAT=10.8650
set LNG=106.8000

for /l %%i in (1,1,3) do (
    echo [Update %%i/3] Vị trí: (!LAT!, !LNG!)
    
    curl -X PUT "http://localhost:8088/api/drivers/%DRIVER_ID%/location" ^
      -H "Content-Type: application/json" ^
      -H "Authorization: Bearer %DRIVER_TOKEN%" ^
      -d "{\"latitude\":!LAT!,\"longitude\":!LNG!}" ^
      -s
    echo.
    
    REM Di chuyển gần hơn
    set /a "LAT_INT=!LAT:~-4!"
    set /a "LAT_INT=!LAT_INT!+20"
    set LAT=10.8670
    set LNG=106.8010
    
    timeout /t 3 /nobreak > nul
)

echo.
echo ✓ Đã cập nhật vị trí tài xế theo thời gian thực
echo.
timeout /t 2 /nobreak > nul

REM ----------------------------------------------------------------------------
REM Tài xế US4 (cont): Bắt đầu chuyến đi sau khi đón khách
REM ----------------------------------------------------------------------------
echo.
echo [Tài xế US4-Start] Bắt đầu chuyến đi
echo ================================================
echo.
echo Tài xế đã đón khách, bắt đầu chuyến đi...
echo.

curl -X POST "http://localhost:8088/api/trips/%TRIP_ID%/start" ^
  -H "Authorization: Bearer %DRIVER_TOKEN%" ^
  -s -w "\nHTTP Status: %%{http_code}\n"

echo.
echo ✓ Chuyến đi đã bắt đầu (status: IN_PROGRESS)
echo.
timeout /t 2 /nobreak > nul

REM ----------------------------------------------------------------------------
REM Tài xế US5: Hoàn thành chuyến đi
REM ----------------------------------------------------------------------------
echo.
echo [Tài xế US5] Hoàn thành chuyến đi
echo ================================================
echo.
echo Tài xế trả khách, hoàn thành chuyến đi...
echo.

curl -X POST "http://localhost:8088/api/trips/%TRIP_ID%/complete" ^
  -H "Authorization: Bearer %DRIVER_TOKEN%" ^
  -s -w "\nHTTP Status: %%{http_code}\n"

echo.
echo ✓ Chuyến đi đã hoàn thành
echo.
timeout /t 2 /nobreak > nul

REM ----------------------------------------------------------------------------
REM Tài xế US5 (cont): Xem lịch sử và doanh thu
REM ----------------------------------------------------------------------------
echo.
echo [Tài xế US5-History] Xem lịch sử chuyến đi
echo ================================================
echo.

curl -X GET "http://localhost:8088/api/trips/driver/%DRIVER_ID%/history?page=1&limit=10" ^
  -H "Authorization: Bearer %DRIVER_TOKEN%" ^
  -s

echo.
echo.

echo [Tài xế US5-Earnings] Xem doanh thu hôm nay
echo ================================================
echo.

curl -X GET "http://localhost:8088/api/trips/driver/%DRIVER_ID%/earnings?period=today" ^
  -H "Authorization: Bearer %DRIVER_TOKEN%" ^
  -s

echo.
echo.
echo ✓ Đã xem lịch sử và doanh thu
echo.

REM ============================================================================
REM TỔNG KẾT
REM ============================================================================

echo.
echo ╔════════════════════════════════════════════════════════════════╗
echo ║  HOÀN THÀNH DEMO ĐẦY ĐỦ 10 USER STORIES                       ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.
echo PHẦN I: HÀNH KHÁCH (5 Stories)
echo   ✓ US1: Đăng ký và đăng nhập
echo   ✓ US2: Ước tính giá và tạo chuyến đi
echo   ✓ US3: Theo dõi vị trí tài xế
echo   ✓ US4: Hủy chuyến đi
echo   ✓ US5: Đánh giá và xem lịch sử
echo.
echo PHẦN II: TÀI XẾ (5 Stories)
echo   ✓ US1: Đăng ký với thông tin xe
echo   ✓ US2: Bật trạng thái sẵn sàng
echo   ✓ US3: Xem và chấp nhận chuyến đi
echo   ✓ US4: Cập nhật vị trí và bắt đầu chuyến
echo   ✓ US5: Hoàn thành và xem doanh thu
echo.
echo Tổng số API calls: 25+
echo Thời gian demo: ~3-4 phút
echo.
echo [INFO] Credentials đã sử dụng:
echo   Passenger: %PASSENGER_EMAIL% / %PASSENGER_PASSWORD%
echo   Driver: %DRIVER_EMAIL% / %DRIVER_PASSWORD%
echo   Trip ID: %TRIP_ID%
echo.

REM Cleanup temp files
del passenger_register.json 2>nul
del passenger_token.json 2>nul
del trip_estimate.json 2>nul
del trip_created.json 2>nul
del trip_created2.json 2>nul
del driver_register.json 2>nul
del driver_token.json 2>nul

echo Press any key to exit...
pause > nul
