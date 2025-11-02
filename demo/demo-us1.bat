@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo.
echo ====================================================================
echo   [US1] Register and Login (API responses + DB verification)
echo ====================================================================
echo.

REM Direct service URLs (not through gateway)
set "USER_URL=http://localhost:8080"

REM Database connection settings (containers from docker-compose)
set "USER_DB=uit-go-backend-postgres-user-1"
set "USER_DB_NAME=uit_go_user_db"
set "USER_DB_USER=uit_go_user"

REM Output folder is this script directory
set "OUT_DIR=%~dp0"

REM Generate random email
set /a RAND=%RANDOM% * 100 + 1
set "P_EMAIL=passenger_%RAND%@uit.edu.vn"
set "P_PASSWORD=Pass123!"

echo [Step 1/3] Register passenger
echo Email: %P_EMAIL%
echo Password: %P_PASSWORD%
echo.

curl.exe -s -X POST %USER_URL%/users ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"%P_EMAIL%\",\"password\":\"%P_PASSWORD%\",\"fullName\":\"Nguyen Van A\",\"phone\":\"0909123456\",\"role\":\"PASSENGER\"}" ^
  -o "%OUT_DIR%p_reg.json"

echo [Response]
type "%OUT_DIR%p_reg.json"
echo.

for /f "delims=" %%a in ('powershell -Command "(Get-Content '%OUT_DIR%p_reg.json' -ErrorAction SilentlyContinue | ConvertFrom-Json).id"') do set P_ID=%%a

if "%P_ID%"=="" (
    echo [ERROR] Failed to register passenger
    exit /b 1
)

echo Passenger ID: %P_ID%
echo.
echo [DB CHECK] Query user record by id
echo.
docker exec -i %USER_DB% psql -U %USER_DB_USER% -d %USER_DB_NAME% -c "SELECT id, email, full_name, phone, role, created_at FROM users WHERE id='%P_ID%';"
echo.

echo [Step 2/3] Login to get JWT token
echo.
curl.exe -s -X POST %USER_URL%/sessions ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"%P_EMAIL%\",\"password\":\"%P_PASSWORD%\"}" ^
  -o "%OUT_DIR%p_token.json"

echo [Response]
type "%OUT_DIR%p_token.json"
echo.

for /f "delims=" %%a in ('powershell -Command "(Get-Content '%OUT_DIR%p_token.json' -ErrorAction SilentlyContinue | ConvertFrom-Json).access_token"') do set P_TOKEN=%%a

if "%P_TOKEN%"=="" (
    echo [ERROR] Failed to login
    exit /b 1
)

echo JWT Token (prefix): %P_TOKEN:~0,60%...
echo.

echo [DB CHECK] Verify user exists by email
echo.
docker exec -i %USER_DB% psql -U %USER_DB_USER% -d %USER_DB_NAME% -c "SELECT id, email, role, created_at FROM users WHERE email='%P_EMAIL%';"
echo.

echo [DONE] US1 completed successfully.
echo Outputs saved in: %OUT_DIR%

if not defined NO_PAUSE pause
exit /b 0
