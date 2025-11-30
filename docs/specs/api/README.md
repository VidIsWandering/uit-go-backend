# API Specifications Index

Tài liệu này định nghĩa chi tiết các hợp đồng giao tiếp (API Contracts) giữa các microservices trong hệ thống UIT-Go.

## Danh sách Services

Hệ thống bao gồm 3 microservices chính:

1.  **[User Service](./user-service.md)**

    - **Role**: Quản lý người dùng (Hành khách & Tài xế).
    - **Key APIs**: Đăng ký, Đăng nhập, Lấy hồ sơ.

2.  **[Trip Service](./trip-service.md)**

    - **Role**: Quản lý vòng đời chuyến đi (Booking Flow).
    - **Key APIs**: Đặt xe, Hủy chuyến, Chấp nhận/Từ chối, Hoàn thành, Lịch sử.

3.  **[Driver Service](./driver-service.md)**
    - **Role**: Quản lý vị trí và trạng thái tài xế.
    - **Key APIs**: Cập nhật vị trí (Geo), Tìm kiếm tài xế (Search), Bật/Tắt trạng thái.

## Quy ước chung (Conventions)

- **Protocol**: RESTful API over HTTP/1.1
- **Data Format**: JSON (Content-Type: `application/json`)
- **Authentication**: Bearer Token (JWT) trong Header `Authorization`.
- **Date Time**: ISO 8601 format (e.g., `2025-10-25T10:00:00Z`).
