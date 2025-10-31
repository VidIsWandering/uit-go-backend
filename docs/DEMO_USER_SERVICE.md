# Demo User Service

Script này sẽ hướng dẫn bạn demo toàn bộ chức năng của user-service, bao gồm cả local và Docker deployment.

## 1. Chạy với Docker

### 1.1 Setup Environment
```bash
# Clone repository nếu chưa có
git clone https://github.com/VidIsWandering/uit-go-backend.git
cd uit-go-backend

# Tạo file .env
cat > .env << EOL
POSTGRES_USER_USER=uit_go_user
POSTGRES_USER_PASSWORD=testpass123
POSTGRES_USER_DB=uit_go_user_db
JWT_SECRET=your-super-secret-key-for-testing-only
EOL
```

### 1.2 Build và Run với Docker Compose
```bash
# Build và chạy toàn bộ services
docker compose up --build -d

# Kiểm tra logs
docker compose logs -f user-service

# Kiểm tra health
curl http://localhost:8080/actuator/health
```

## 2. Demo API với Postman

### 2.1 Import Postman Collection

1. Mở Postman
2. Click "Import"
3. Copy JSON sau vào:

```json
{
  "info": {
    "name": "UIT-Go User Service Demo",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "1. Register Passenger",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "url": "http://localhost:8088/api/users",
        "body": {
          "mode": "raw",
          "raw": "{\n    \"email\": \"passenger@uit.edu.vn\",\n    \"password\": \"password123\",\n    \"full_name\": \"Demo Passenger\",\n    \"phone\": \"0123456789\",\n    \"role\": \"PASSENGER\"\n}"
        }
      }
    },
    {
      "name": "2. Register Driver",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "url": "http://localhost:8088/api/users",
        "body": {
          "mode": "raw",
          "raw": "{\n    \"email\": \"driver@uit.edu.vn\",\n    \"password\": \"password123\",\n    \"full_name\": \"Demo Driver\",\n    \"phone\": \"0987654321\",\n    \"role\": \"DRIVER\",\n    \"vehicle_info\": {\n        \"plate_number\": \"51G-123.45\",\n        \"model\": \"Toyota Vios\",\n        \"type\": \"4_SEATS\"\n    }\n}"
        }
      }
    },
    {
      "name": "3. Login Passenger",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "url": "http://localhost:8088/api/sessions",
        "body": {
          "mode": "raw",
          "raw": "{\n    \"email\": \"passenger@uit.edu.vn\",\n    \"password\": \"password123\"\n}"
        }
      }
    },
    {
      "name": "4. Login Driver",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "url": "http://localhost:8088/api/sessions",
        "body": {
          "mode": "raw",
          "raw": "{\n    \"email\": \"driver@uit.edu.vn\",\n    \"password\": \"password123\"\n}"
        }
      }
    },
    {
      "name": "5. Get Passenger Profile",
      "request": {
        "method": "GET",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{passenger_token}}"
          }
        ],
        "url": "http://localhost:8088/api/users/me"
      }
    },
    {
      "name": "6. Get Driver Profile",
      "request": {
        "method": "GET",
        "header": [
          {
            "key": "Authorization",
            "value": "Bearer {{driver_token}}"
          }
        ],
        "url": "http://localhost:8088/api/users/me"
      }
    }
  ]
}
```

### 2.2 Setup Environment Variables trong Postman

1. Click vào Collection
2. Click vào tab "Variables"
3. Thêm các variables:
   - `passenger_token`: [để trống - sẽ được điền sau khi login]
   - `driver_token`: [để trống - sẽ được điền sau khi login]

### 2.3 Chạy Demo

1. **Register Passenger**
   - Chạy request "1. Register Passenger"
   - Verify response có status 201 và passenger_id

2. **Register Driver**
   - Chạy request "2. Register Driver"
   - Verify response có status 201 và driver_id
   - Verify response có vehicle_info

3. **Login Passenger**
   - Chạy request "3. Login Passenger"
   - Copy access_token từ response
   - Paste vào Collection Variable "passenger_token"

4. **Login Driver**
   - Chạy request "4. Login Driver"
   - Copy access_token từ response
   - Paste vào Collection Variable "driver_token"

5. **Get Passenger Profile**
   - Chạy request "5. Get Passenger Profile"
   - Verify thông tin passenger trả về đúng

6. **Get Driver Profile**
   - Chạy request "6. Get Driver Profile"
   - Verify thông tin driver trả về đúng

## 3. Error Cases Demo

### 3.1 Register với email đã tồn tại
```bash
curl -X POST http://localhost:8088/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "email": "passenger@uit.edu.vn",
    "password": "password123",
    "full_name": "Test User",
    "phone": "0123456789",
    "role": "PASSENGER"
  }'
```
Expected: Status 400, error "email_exists"

### 3.2 Login với password sai
```bash
curl -X POST http://localhost:8088/api/sessions \
  -H "Content-Type: application/json" \
  -d '{
    "email": "passenger@uit.edu.vn",
    "password": "wrongpass"
  }'
```
Expected: Status 401, error "invalid_credentials"

### 3.3 Get Profile với invalid token
```bash
curl http://localhost:8088/api/users/me \
  -H "Authorization: Bearer invalid-token"
```
Expected: Status 401

## 4. Cleanup

```bash
# Dừng và xóa containers
docker compose down

# Xóa volumes (cẩn thận - sẽ xóa data)
docker compose down -v
```

## Notes

1. **Security**:
   - JWT_SECRET trong demo chỉ để test
   - Trong production cần dùng strong secret
   - Không expose JWT_SECRET trong code/repo

2. **Data Persistence**:
   - Data được lưu trong Docker volume
   - Volume vẫn giữ data khi restart
   - Chỉ mất khi chạy `down -v`

3. **Troubleshooting**:
   - Check logs: `docker compose logs user-service`
   - Check health: `curl localhost:8080/actuator/health`
   - Check DB: `docker compose exec postgres-user psql -U uit_go_user -d uit_go_user_db`