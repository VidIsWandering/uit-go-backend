# Đồ án SE360: Xây dựng Nền tảng "UIT-Go" Cloud-Native

Đây là repository cho dự án backend của UIT-Go, một ứng dụng gọi xe giả tưởng. Hệ thống được xây dựng trên kiến trúc microservices.

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

## 4. Hướng dẫn Chạy Local (Quan trọng)

Để chạy toàn bộ hệ thống trên máy của bạn, bạn cần cài đặt **Docker** và **Docker Compose**.

### Bước 1: Chuẩn bị file Môi trường (.env)

File `.env` chứa các mật khẩu CSDL. File này đã bị chặn bởi `.gitignore` vì lý do bảo mật. Bạn cần tạo file này thủ công:

1.  Copy file `.env.example` thành một file mới tên là `.env`:
    ```bash
    cp .env.example .env
    ```
2.  Mở file `.env` và điền các mật khẩu của bạn vào trường `<your_secret_password>`.

### Bước 2: Khởi chạy hệ thống

Mở terminal ở thư mục gốc của dự án và chạy lệnh sau:

```bash
docker-compose up --build