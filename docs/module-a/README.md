# Module A: Thiết kế Kiến trúc cho Scalability & Performance

## 1. Tổng quan

Module này tập trung vào việc chuyển đổi hệ thống UIT-Go từ kiến trúc cơ bản sang kiến trúc **Hyper-scale**, có khả năng chịu tải cao và mở rộng linh hoạt.
Vai trò: **System Architect**.

## 2. Các Quyết định Kiến trúc (ADRs)

Chúng tôi đã phân tích và đưa ra các quyết định quan trọng sau:

- **[ADR-001: Async Communication (SQS)](../adr/module-a/001-architecture-async-processing.md)**
  - **Vấn đề**: API đặt xe đồng bộ gây nghẽn cổ chai.
  - **Giải pháp**: Sử dụng SQS để tách rời TripService và DriverService.
- **[ADR-002: Database Read Scalability](../adr/module-a/002-database-read-replicas.md)**
  - **Vấn đề**: Database quá tải vì lượng query đọc lớn.
  - **Giải pháp**: Triển khai Read Replicas.
- **[ADR-003: Caching Strategy](../adr/module-a/003-caching-strategy.md)**
  - **Vấn đề**: Độ trễ cao khi truy xuất dữ liệu tĩnh/geo.
  - **Giải pháp**: Redis Cache & Geo-spatial.
- **[ADR-004: Auto-scaling Strategy](../adr/module-a/004-autoscaling-strategy.md)**
  - **Vấn đề**: Lãng phí tài nguyên giờ thấp điểm, sập giờ cao điểm.
  - **Giải pháp**: ECS Service Auto Scaling & RDS Storage Scaling.

## 3. Kế hoạch Thực hiện

Chi tiết lộ trình triển khai xem tại: **[PLAN.md](./PLAN.md)**.

## 4. Kiến trúc Hệ thống (Target Architecture)

_(Sẽ được cập nhật sau khi hoàn tất triển khai Terraform)_

### Luồng Đặt xe (Booking Flow) - Asynchronous

1.  **Client** -> `POST /trips` -> **TripService**
2.  **TripService** -> Push Message -> **SQS**
3.  **TripService** -> `202 Accepted` -> **Client**
4.  **DriverService** (Worker) -> Poll Message -> **SQS**
5.  **DriverService** -> Find Drivers (Redis Geo) -> Notify Driver
