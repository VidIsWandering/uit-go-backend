# User Service

Microservice quản lý người dùng của hệ thống UIT-Go, xây dựng bằng Spring Boot.

## Tính năng

- Đăng ký tài khoản (POST /users)
- Đăng nhập, nhận JWT token (POST /sessions) 
- Xem thông tin cá nhân (GET /users/me)

## Yêu cầu

- Java 21 (Temurin/Eclipse)
- Maven
- PostgreSQL (cho production) hoặc H2 (cho development)
- Docker & Docker Compose (optional)

## Cài đặt

1. Clone repository:
```bash
git clone https://github.com/VidIsWandering/uit-go-backend.git
cd uit-go-backend
```

2. Cấu hình môi trường:
```bash
# Copy file .env.example thành .env
cp .env.example .env

# Chỉnh sửa .env và thêm các giá trị phù hợp:
# - POSTGRES_USER_PASSWORD: Password cho PostgreSQL user service
# - JWT_SECRET: Secret key dài ít nhất 32 ký tự cho JWT
```

3. Chạy ứng dụng:

### Development (H2 Database)
```bash
cd user-service
mvn spring-boot:run
```

### Production với Docker
```bash
# Build và chạy tất cả services
docker-compose up -d

# Chỉ chạy user-service
docker-compose up -d user-service
```

## Môi trường

Service hỗ trợ 2 profiles:

### Development (default)
- H2 in-memory database
- H2 Console enabled (/h2-console)
- DDL auto = update

### Production
- PostgreSQL database
- H2 Console disabled
- DDL auto = validate
- JWT required

## Biến Môi Trường

| Biến | Mô tả | Mặc định |
|------|--------|---------|
| `JWT_SECRET` | Secret key cho JWT (>= 32 ký tự) | Bắt buộc trong prod |
| `SPRING_PROFILES_ACTIVE` | Profile (dev/prod) | dev |
| `SPRING_DATASOURCE_URL` | Database URL | H2 mem (dev) |
| `SPRING_DATASOURCE_USERNAME` | Database username | sa (dev) |
| `SPRING_DATASOURCE_PASSWORD` | Database password | (empty) |

## Tạo JWT Secret An Toàn

Để tạo JWT secret mạnh, sử dụng một trong các cách:

```bash
# Linux/macOS (openssl)
openssl rand -base64 32

# Windows PowerShell
$bytes = New-Object byte[] 32
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($bytes)
[Convert]::ToBase64String($bytes)
```

## Kiểm tra hoạt động

```bash
# Kiểm tra health check
curl http://localhost:8080/actuator/health

# Đăng ký user mới
curl -X POST http://localhost:8080/users -H "Content-Type: application/json" \
  -d '{"email":"test@example.com", "password":"secret", "fullName":"Test User"}'

# Đăng nhập
curl -X POST http://localhost:8080/sessions -H "Content-Type: application/json" \
  -d '{"email":"test@example.com", "password":"secret"}'
```

## Contributing

1. Fork repository
2. Tạo feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -am 'Add amazing feature'`)
4. Push branch (`git push origin feature/amazing`)
5. Tạo Pull Request
