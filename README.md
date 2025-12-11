# UIT-Go Backend

UIT-Go là hệ thống backend microservices cho ứng dụng gọi xe, được thiết kế cloud-native, triển khai trên AWS với hạ tầng IaC (Terraform), hỗ trợ auto-scaling, caching, event-driven và tối ưu cho hiệu năng cao.

## 1. Kiến trúc tổng quan

![AWS Cloud Architecture](images/architecture/aws-cloud-architecture.png)

- Xem chi tiết sơ đồ và giải thích tại [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- Toàn bộ quyết định thiết kế, trade-off: [`docs/adr/README.md`](docs/adr/README.md)

## 2. Cài đặt & chạy hệ thống LOCAL (Docker Compose)

### Yêu cầu

- Docker & Docker Compose
- Java 21 (user-service, trip-service)
- Node.js 18+ (driver-service)

### Các bước thực hiện

```bash
# 1. Clone repo
 git clone https://github.com/VidIsWandering/uit-go-backend.git
 cd uit-go-backend

# 2. Tạo file .env
 cp .env.example .env
# (Điền các biến môi trường cần thiết, xem hướng dẫn trong file .env.example)

# 3. Khởi động toàn bộ hệ thống
 docker compose up --build
```

- Truy cập các service:
  - User Service: http://localhost:8089
  - Trip Service: http://localhost:8081
  - Driver Service: http://localhost:8082
- Health check:
  ```bash
  curl http://localhost:8089/actuator/health
  curl http://localhost:8081/actuator/health
  ```
- Monitoring local: Prometheus (http://localhost:9090), Grafana (http://localhost:3000)

## 3. Cài đặt & triển khai hệ thống trên AWS (Terraform + ECS)

### Yêu cầu

- Tài khoản AWS, đã tạo IAM User với quyền admin
- Terraform CLI (~> v1.13)
- AWS CLI
- Docker

### Các bước thực hiện

```bash
# 1. Cấu hình AWS credentials (Access Key, Secret Key)
 export AWS_ACCESS_KEY_ID=...
 export AWS_SECRET_ACCESS_KEY=...

# 2. Khởi tạo và apply hạ tầng
 cd terraform
 terraform init
 terraform apply
# (Nhập yes để xác nhận)

# 3. Build & push Docker images lên ECR (lặp lại cho từng service)
 aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account_id>.dkr.ecr.<region>.amazonaws.com
 docker build -t <repo_url>:latest .
 docker push <repo_url>:latest

# 4. Cập nhật image trong Terraform, apply lại để ECS sử dụng image mới
 terraform apply

# 5. Lấy DNS của ALB và kiểm tra API
 terraform output alb_dns_name
# Truy cập http://<alb_dns_name>/users, /trips, /drivers
```

> **Lưu ý:** Sau khi sử dụng xong, hãy chạy `terraform destroy` để tránh phát sinh chi phí AWS không mong muốn.

## 4. Tài liệu & đặc tả kỹ thuật

- Kiến trúc hệ thống: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- Báo cáo tổng kết: [`docs/REPORT.md`](docs/REPORT.md)
- Quyết định thiết kế (ADR): [`docs/adr/README.md`](docs/adr/README.md)
- Đặc tả API: [`docs/specs/api/`](docs/specs/api/)
- Kết quả load test & tuning: [`docs/module-a/`](docs/module-a/)

## 5. Cấu trúc thư mục chính

```
uit-go-backend/
├── user-service/     # Java Spring Boot
├── driver-service/   # Node.js Express
├── trip-service/     # Java Spring Boot
├── gateway/          # NGINX API Gateway
├── monitoring/       # Prometheus & Grafana configs (local)
├── terraform/        # IaC AWS
├── docs/             # Tài liệu kiến trúc, ADR, báo cáo, specs
└── ...
```

---
