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

## 1. Kiến trúc Tổng quan 🏗️

Hệ thống bao gồm 3 microservices cơ bản, mỗi service có CSDL riêng (Database per Service) và được đóng gói bằng Docker.

- **UserService (Java - Spring Boot):**
  - **Port:** `8080`
  - **Trách nhiệm:** Quản lý thông tin người dùng (hành khách và tài xế), xử lý đăng ký, đăng nhập và hồ sơ.
  - **CSDL:** PostgreSQL (AWS RDS).
- **TripService (Java - Spring Boot):**
  - **Port:** `8081`
  - **Trách nhiệm:** Dịch vụ trung tâm, xử lý logic tạo chuyến đi, quản lý các trạng thái của chuyến.
  - **CSDL:** PostgreSQL (AWS RDS).
- **DriverService (Node.js - Express):**
  - **Port:** `8082`
  - **Trách nhiệm:** Quản lý trạng thái **(Online/Offline)** và vị trí của tài xế theo thời gian thực. Cung cấp API để tìm kiếm các tài xế phù hợp ở gần.
  - **CSDL:** Redis (AWS ElastiCache) với Geospatial.

_(Xem chi tiết sơ đồ kiến trúc tại: `docs/ARCHITECTURE.md`)_

## 2. Quyết định Kiến trúc (ADRs) 🧭

Các quyết định thiết kế và đánh đổi (trade-offs) quan trọng của dự án được ghi lại tại thư mục `/docs/adr/`. Đây là bằng chứng cho quá trình tư duy thiết kế của nhóm. Vui lòng đọc các file sau:

1.  **[ADR 001: Lựa chọn RESTful API](docs/adr/001-chon-restful-api.md):** Giao tiếp giữa các service.
2.  **[ADR 002: Lựa chọn Redis Geospatial](docs/adr/002-chon-redis-geospatial.md):** Lưu trữ và truy vấn vị trí.
3.  **[ADR 003: Lựa chọn Kiến trúc Đa ngôn ngữ](docs/adr/003-chon-kien-truc-da-ngon-ngu.md):** Sử dụng Java và Node.js song song.
4.  **[ADR 004: Lựa chọn Polling cho Theo dõi Vị trí](docs/adr/004-chon-polling-cho-theo-doi-vi-tri.md):** Giải pháp "real-time" cho Passenger US3.
5.  **[ADR 005: Lựa chọn Terraform (IaC)](docs/adr/005-chon-terraform-de-quan-ly-ha-tang.md):** Quản lý hạ tầng bằng code .
6.  **[ADR 006: Sử dụng Secrets Manager cho Mật khẩu RDS](docs/adr/006-su-dung-secrets-manager-cho-mat-khau-rds.md):** Bảo mật mật khẩu CSDL.
7.  **[ADR 007: Đặt CSDL trong Private Subnets](docs/adr/007-dat-csdl-trong-private-subnets.md):** Tăng cường bảo mật mạng cho CSDL.
8.  **[ADR 008: Lựa chọn ECS để Triển khai Container](docs/adr/008-chon-ecs-de-trien-khai-container.md):** Chiến lược triển khai lên AWS.
9.  **[ADR 009: Lựa chọn Fargate Launch Type cho ECS](docs/adr/009-chon-fargate-launch-type-cho-ecs.md):** Sử dụng chế độ serverless cho ECS.

## 3. Hợp đồng API (API Contracts) 📜

Toàn bộ API (request/response) của 3 services, bao gồm đủ 10 User Stories, được định nghĩa chi tiết tại file:
**[docs/API_CONTRACTS.md](docs/API_CONTRACTS.md)**

---

## 4. Hướng dẫn Chạy Local (Docker Compose) 🐳

Hướng dẫn này giúp bạn chạy toàn bộ hệ thống UIT-Go Backend trên máy local để phát triển và kiểm thử.

### Yêu cầu
- Đã cài đặt **Docker** và **Docker Compose (v2)**
- Có sẵn **Java 21** và **Node.js 18+**
- Không cần cài PostgreSQL/Redis riêng — chúng sẽ chạy trong container.

---

### Bước 1: Clone repository
```bash
git clone https://github.com/VidIsWandering/uit-go-backend.git
cd uit-go-backend
Bước 2: Chuẩn bị file môi trường (.env)
File .env lưu cấu hình cơ sở dữ liệu và biến môi trường local.

Tạo file .env:

bash
Copy code
cp .env.example .env
Điền các giá trị cần thiết vào file .env:

env
Copy code
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
Bước 3: Khởi chạy hệ thống bằng Docker Compose
Tại thư mục gốc, chạy lệnh:

bash
Copy code
docker compose up --build
Docker Compose sẽ:

Khởi chạy 3 cơ sở dữ liệu (2 PostgreSQL, 1 Redis).

Build và khởi động 3 service (2 Java, 1 Node.js).

Tự động kết nối các service qua internal network.

Bạn sẽ thấy logs xuất ra từ từng container khi khởi động thành công.

Bước 4: Kiểm tra dịch vụ
Khi khởi động xong, bạn có thể truy cập:

http://localhost:8080 → UserService

http://localhost:8081 → TripService

http://localhost:8082 → DriverService

Kiểm tra health:

bash
Copy code
curl http://localhost:8080/actuator/health
curl http://localhost:8081/actuator/health
Bước 5: Chạy thủ công từng service (tuỳ chọn)
Nếu muốn debug hoặc phát triển riêng lẻ từng service:

User Service (Java)
bash
Copy code
cd user-service
./mvnw spring-boot:run
Trip Service (Java)
bash
Copy code
cd trip-service
./mvnw spring-boot:run
Driver Service (Node.js)
bash
Copy code
cd driver-service
npm install
npm run dev
Bước 6: Kiểm thử
Unit Tests
bash
Copy code
# User Service
cd user-service
./mvnw test

# Driver Service
cd driver-service
npm test
Integration Tests (với TestContainers)
bash
Copy code
cd user-service
./mvnw failsafe:integration-test
API Testing (ví dụ)
bash
Copy code
# Đăng ký người dùng mới
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@uit.edu.vn",
    "password": "password123",
    "fullName": "Test User",
    "phone": "0123456789",
    "role": "PASSENGER"
  }'
Bước 7: Monitoring Local
Prometheus: http://localhost:9090

Grafana: http://localhost:3000 (mặc định admin/admin)

Kiểm tra health status nhanh:

bash
Copy code
curl http://localhost:8080/actuator/health
curl http://localhost:8081/actuator/health
## 5. Hướng dẫn Chạy Hạ tầng (IaC - Terraform) 🏗️

Phần này hướng dẫn cách tạo hạ tầng **thực tế** (VPC, RDS, ElastiCache, ECS Cluster...) trên AWS bằng Terraform.

**Yêu cầu:**

- Đã cài đặt **Terraform CLI** (~> v1.13).
- Đã có tài khoản **AWS** thông thường.
- Đã tạo **IAM User** với quyền AdministratorAccess và có **Access Key ID**, **Secret Access Key**.

### Bước 1: Cấu hình AWS Credentials

Mở terminal WSL của bạn và chạy 2 lệnh sau, thay thế bằng key của bạn:

```bash
export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_ACCESS_KEY"
```

### Bước 2: Khởi tạo Terraform

Di chuyển vào thư mục `terraform` và chạy `init`:

```bash
cd terraform
terraform init
```

### Bước 3: Xem Kế hoạch (Tùy chọn)

Kiểm tra xem Terraform sẽ tạo/thay đổi những gì:

```bash
terraform plan
```

### Bước 4: Tạo/Cập nhật Hạ tầng

Chạy lệnh sau để tạo hoặc cập nhật các tài nguyên trên AWS. **Quá trình này có thể mất vài phút đến ~20 phút tùy thuộc vào tài nguyên (RDS tạo lâu nhất).**

```bash
terraform apply
```

Nhập yes khi được hỏi để xác nhận.

Sau khi hoàn thành, Terraform sẽ in ra các Outputs quan trọng (endpoints CSDL, ARN secrets...).

### Bước 5: Hủy Hạ tầng (Quan trọng)

Sau khi sử dụng xong, **hãy xóa toàn bộ tài nguyên** để tránh phát sinh chi phí:

```bash
terraform destroy
```

Nhập yes khi được hỏi để xác nhận.

## 6. Hướng dẫn Triển khai Lên AWS (ECS) 🚀

Phần này mô tả quy trình build Docker images cho các service và triển khai chúng lên hạ tầng AWS đã được tạo bằng Terraform (ở Mục 5).

**Yêu cầu:**
* Đã hoàn thành các bước trong Mục 5 (Hạ tầng IaC đã được `apply`).
* Đã cài đặt **AWS CLI** và cấu hình credentials (hoặc đảm bảo biến môi trường AWS keys vẫn còn hiệu lực).
* Đã cài đặt **Docker**.
* Code của cả 3 services (`user-service`, `trip-service`, `driver-service`) đã hoàn thiện và sẵn sàng để build.

### Bước 1: Build, Tag và Push Docker Images lên ECR

Lặp lại các bước sau cho **từng service** (`user-service`, `trip-service`, `driver-service`):

1.  **Xác thực Docker với ECR:** Lấy lệnh đăng nhập từ AWS CLI và thực thi nó. Thay `<aws_account_id>` và `<region>` bằng thông tin tài khoản của bạn.
    ```bash
    aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<region>.amazonaws.com
    ```
    *(Ví dụ region: `ap-southeast-1`)*

2.  **Lấy URL của ECR Repository:** Chạy `terraform output` trong thư mục `terraform` để lấy URL repo của service tương ứng (ví dụ: `ecr_repository_urls.user`). Hoặc bạn có thể xem trực tiếp trên AWS ECR Console.
    ```bash
    cd ../terraform 
    terraform output ecr_repository_urls 
    cd .. 
    # Copy lại URL cho service bạn đang build, ví dụ: <account_id>.dkr.ecr.<region>[.amazonaws.com/uit-go/user-service](https://.amazonaws.com/uit-go/user-service)
    ```

3.  **Build Docker Image:** Di chuyển vào thư mục của service và chạy lệnh build. Thay `<repo_url>` bằng URL bạn vừa lấy.
    ```bash
    # Ví dụ cho user-service:
    cd user-service
    docker build -t <repo_url>:latest . 
    # Ví dụ: docker build -t [123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/uit-go/user-service:latest](https://123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/uit-go/user-service:latest) .
    cd .. 
    ```
    *(Đối với service Java, lệnh build này sẽ chạy multi-stage build trong Dockerfile).*

4.  **Push Docker Image:** Đẩy image vừa build lên ECR.
    ```bash
    # Ví dụ cho user-service:
    docker push <repo_url>:latest
    # Ví dụ: docker push [123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/uit-go/user-service:latest](https://123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/uit-go/user-service:latest)
    ```

*(Lặp lại bước 1-4 cho `trip-service` và `driver-service`)*

### Bước 2: Cập nhật Task Definitions trong Terraform

Sau khi cả 3 image đã được đẩy lên ECR:

1.  **Mở file `terraform/main.tf`**.
2.  Tìm đến 3 khối `resource "aws_ecs_task_definition"` (`user_service_task`, `trip_service_task`, `driver_service_task`).
3.  Trong mỗi khối, **sửa lại thuộc tính `image`** từ `"nginx:latest"` thành **URL ECR repository** tương ứng mà bạn đã push image lên (bao gồm cả tag `:latest`).
    *Ví dụ cho `user_service_task`:*
    ```terraform
      container_definitions = jsonencode([
        {
          name      = "user-service" 
          # --- SỬA DÒNG NÀY ---
          image     = "<account_id>.dkr.ecr.<region>[.amazonaws.com/uit-go/user-service:latest](https://.amazonaws.com/uit-go/user-service:latest)" 
          essential = true          
          # ... (phần còn lại giữ nguyên)
    ```
    *(Sửa tương tự cho `trip_service_task` và `driver_service_task`).*

### Bước 3: Áp dụng thay đổi và Deploy

1.  **Di chuyển vào thư mục `terraform`**.
2.  **Chạy `terraform plan`** để kiểm tra xem Terraform có phát hiện đúng sự thay đổi trong 3 Task Definitions không.
3.  **Chạy `terraform apply`** để tạo phiên bản mới cho Task Definitions và tự động cập nhật ECS Services để sử dụng image mới.
    ```bash
    terraform plan
    terraform apply 
    ```
    Nhập `yes` để xác nhận. ECS Fargate sẽ tự động thực hiện rolling update để triển khai phiên bản mới.

### Bước 4: Kiểm tra Hệ thống trên AWS

1.  **Lấy DNS Name của ALB:** Chạy `terraform output` trong thư mục `terraform` để lấy `alb_dns_name` (chúng ta cần thêm output này) hoặc xem trực tiếp trên AWS Console (EC2 -> Load Balancers -> Chọn `uit-go-alb` -> Copy DNS name).
2.  **Sử dụng Postman/curl:** Gửi request đến các API của bạn thông qua DNS name của ALB (ví dụ: `http://<alb_dns_name>/users`, `http://<alb_dns_name>/drivers/search?lat=...`).

---
