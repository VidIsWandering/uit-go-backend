# Đồ án SE360: Xây dựng Nền tảng "UIT-Go" Cloud-Native

Đây là repository cho dự án backend của UIT-Go, một ứng dụng gọi xe giả tưởng. Hệ thống được xây dựng trên kiến trúc microservices.

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

Để chạy toàn bộ hệ thống trên máy của bạn cho mục đích phát triển và kiểm thử.

**Yêu cầu:**

- Đã cài đặt **Docker** và **Docker Compose** (v2).

### Bước 1: Chuẩn bị file Môi trường (.env)

File `.env` chứa mật khẩu CSDL giả lập cho môi trường local.

1.  Copy file `.env.example` thành một file mới tên là `.env`:
    ```bash
    cp .env.example .env
    ```
2.  Mở file `.env` và điền các mật khẩu **local** của bạn vào trường `<your_secret_password>`.

### Bước 2: Khởi chạy hệ thống

Mở terminal ở thư mục gốc của dự án và chạy lệnh sau (sử dụng cú pháp Docker Compose v2):

```bash
docker compose up --build
```

Docker Compose sẽ:

1.  Khởi chạy 3 CSDL (2 Postgres, 1 Redis) dưới dạng container.
2.  Build 3 service (2 Java, 1 Node.js) từ `Dockerfile` tương ứng.
3.  Khởi chạy 3 service và kết nối chúng với các CSDL local.

### Bước 3: Kiểm tra Local

Sau khi lệnh chạy xong, bạn có thể kiểm tra bằng Postman hoặc trình duyệt:

- `http://localhost:8080` (UserService)
- `http://localhost:8081` (TripService)
- `http://localhost:8082` (DriverService)

---

## 5. Hướng dẫn Chạy Hạ tầng (IaC - Terraform) 🏗️

Phần này hướng dẫn cách tạo hạ tầng **thực tế** (VPC, RDS, ElastiCache, ECS Cluster...) trên AWS bằng Terraform.

**Yêu cầu:**

- Đã cài đặt **Terraform CLI** (~> v1.13).
- Đã có tài khoản **AWS** thông thường.
- Đã tạo **IAM User** với quyền AdministratorAccess và có **Access Key ID**, **Secret Access Key**.

### Bước 1: Cấu hình AWS Credentials

Mở terminal WSL của bạn và chạy 2 lệnh sau, thay thế bằng key của bạn:

````bash
export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_ACCESS_KEY"

### Bước 2: Khởi tạo Terraform

Di chuyển vào thư mục `terraform` và chạy `init`:

```bash
cd terraform
terraform init
````

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

## 6. Hướng dẫn Triển khai Lên AWS (ECS) 🚀 [Sẽ cập nhật sau]

(Phần này sẽ mô tả cách build Docker images, đẩy lên ECR, và cập nhật/deploy ECS Services)

---
