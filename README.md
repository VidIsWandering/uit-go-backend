# UIT-Go Backend

UIT-Go là một ứng dụng đặt xe được xây dựng với kiến trúc microservices. Repository này chứa phần backend của ứng dụng.

## Cấu trúc Project

```
uit-go-backend/
├── user-service/     # Quản lý user (Java Spring Boot)
├── driver-service/   # Quản lý tài xế (Node.js)
├── trip-service/     # Quản lý chuyến đi (Java Spring Boot)
├── gateway/          # NGINX API Gateway
├── monitoring/       # Prometheus & Grafana configs
├── terraform/        # Infrastructure as Code
└── docs/            # Documentation
```

## Yêu cầu System

- Docker và Docker Compose
- Java 21 (cho user-service và trip-service)
- Node.js 18+ (cho driver-service)
- PostgreSQL 15 (cho local development)
- Redis (cho driver-service)

## 1. Kiến trúc Tổng quan

Hệ thống bao gồm 3 microservices cơ bản, mỗi service có CSDL riêng (Database per Service) và được đóng gói bằng Docker.

* **UserService (Java - Spring Boot):**
    * **Port:** `8080`
    * **Trách nhiệm:** Quản lý đăng ký, đăng nhập, hồ sơ người dùng.
    * **CSDL:** PostgreSQL (riêng biệt).

* **TripService (Java - Spring Boot):**
    * **Port:** `8081`
    * **Trách nhiệm:** Xử lý logic tạo chuyến đi, quản lý trạng thái chuyến.
    * **CSDL:** PostgreSQL (riêng biệt).

* **DriverService (Node.js - Express):**
    * **Port:** `8082`
    * **Trách nhiệm:** Quản lý vị trí tài xế theo thời gian thực và tìm kiếm tài xế.
    * **CSDL:** Redis (với Geospatial).

## 2. Quyết định Kiến trúc (ADRs)

Các quyết định thiết kế và đánh đổi (trade-offs) quan trọng của dự án được ghi lại tại thư mục `/docs/adr/`. Vui lòng đọc các file sau để hiểu lý do:

1.  **[ADR 001: Lựa chọn RESTful API](docs/adr/001-chon-restful-api.md):** Giải thích tại sao chọn REST/JSON (hỗ trợ đa ngôn ngữ).
2.  **[ADR 002: Lựa chọn Redis Geospatial](docs/adr/002-chon-redis-geospatial.md):** Giải thích trade-off "Ưu tiên Tốc độ" cho `DriverService`.
3.  **[ADR 003: Lựa chọn Kiến trúc Đa ngôn ngữ](docs/adr/003-chon-kien-truc-da-ngon-ngu.md):** Giải thích tại sao dùng Java (Spring Boot) và Node.js (Express) song song.

## 3. Hợp đồng API (API Contracts)

Toàn bộ API (request/response) của 3 services được định nghĩa chi tiết tại file:
**[docs/API_CONTRACTS.md](docs/API_CONTRACTS.md)**

---

## Cài đặt & Chạy

### 1. Clone repository
```bash
git clone https://github.com/VidIsWandering/uit-go-backend.git
cd uit-go-backend
```

### 2. Setup Environment Variables
Tạo file `.env` trong thư mục gốc:
```env
# Database
POSTGRES_USER_USER=uit_go_user
POSTGRES_USER_PASSWORD=your_password
POSTGRES_USER_DB=uit_go_user_db

POSTGRES_TRIP_USER=uit_go_trip
POSTGRES_TRIP_PASSWORD=your_password
POSTGRES_TRIP_DB=uit_go_trip_db

# JWT
JWT_SECRET=your_jwt_secret

# Ports (optional)
USER_SERVICE_PORT=8080
TRIP_SERVICE_PORT=8081
DRIVER_SERVICE_PORT=8082
```

### 3. Chạy toàn bộ services với Docker Compose
```bash
docker compose up --build
```

### 4. Chạy từng service riêng lẻ

#### User Service (Java)
```bash
cd user-service
./mvnw spring-boot:run
```

#### Driver Service (Node.js)
```bash
cd driver-service
npm install
npm run dev
```

#### Trip Service (Java)
```bash
cd trip-service
./mvnw spring-boot:run
```

## Testing

### 1. Unit Tests
```bash
# User Service
cd user-service
./mvnw test

# Driver Service
cd driver-service
npm test
```

### 2. Integration Tests (với TestContainers)
```bash
cd user-service
./mvnw failsafe:integration-test
```

### 3. API Testing

#### Register User
```bash
curl -X POST http://localhost:8088/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@uit.edu.vn",
    "password": "password123",
    "full_name": "Test User",
    "phone": "0123456789",
    "role": "PASSENGER"
  }'
```

#### Login
```bash
curl -X POST http://localhost:8088/api/sessions \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@uit.edu.vn",
    "password": "password123"
  }'
```

#### Get Profile (với JWT token)
```bash
curl http://localhost:8088/api/users/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Monitoring

### 1. Access Points
- Grafana: http://localhost:3000 (admin/admin)
- Prometheus: http://localhost:9090

### 2. Health Checks
```bash
# User Service
curl http://localhost:8080/actuator/health

# Trip Service
curl http://localhost:8081/actuator/health
```

## Documentation
- API Contracts: [docs/API_CONTRACTS.md](docs/API_CONTRACTS.md)
- Architecture: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Monitoring: [monitoring/README.md](monitoring/README.md)

## Contributing
1. Fork repository
2. Tạo feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## Security Notes
- Đổi tất cả default passwords trong production
- Không commit các secrets vào repository
- Sử dụng HTTPS trong production
- Review security guidelines trong [docs/SECURITY.md](docs/SECURITY.md)