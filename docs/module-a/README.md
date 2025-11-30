# Module A: Thiết kế Kiến trúc cho Scalability & Performance

## 1. Tổng quan

Module này tập trung vào việc chuyển đổi hệ thống UIT-Go từ kiến trúc cơ bản sang kiến trúc **Hyper-scale**, có khả năng chịu tải cao và mở rộng linh hoạt.
Vai trò: **System Architect**.

## 2. Tài liệu Quy hoạch & Kiến trúc (Planning)

- **[Kế hoạch Thực hiện (Implementation Plan)](./PLAN.md)**: Lộ trình chi tiết các bước thực hiện Module A.
- **Các Quyết định Kiến trúc (ADRs)**:
  - **[ADR-001: Async Communication (SQS)](../adr/module-a/001-architecture-async-processing.md)**
  - **[ADR-002: Database Read Scalability](../adr/module-a/002-database-read-replicas.md)**
  - **[ADR-003: Caching Strategy](../adr/module-a/003-caching-strategy.md)**
  - **[ADR-004: Auto-scaling Strategy](../adr/module-a/004-autoscaling-strategy.md)**
  - **[ADR-005: Concurrency Control](../adr/module-a/005-concurrency-control.md)**

## 3. Môi trường & Hướng dẫn Kiểm thử (Testing)

Để đảm bảo tính khách quan và khả năng tái lập kết quả, chúng tôi đã tài liệu hóa quy trình test:

- **[Hướng dẫn Kiểm chứng (Verification Guide)](./VERIFICATION_GUIDE.md)**: Các bước thực hiện Load Test (Spike, Stress) và cách thu thập dữ liệu.

## 4. Báo cáo Kết quả (Results)

Quá trình tối ưu hóa được chia làm 2 giai đoạn để đo lường hiệu quả:

- **[Giai đoạn 1: Baseline (Load Test 1)](./load-test-1-baseline/README.md)**
  - Trạng thái: **Đã hoàn thành**.
  - Kết quả: Xác định được điểm nghẽn tại Database Connection Pool.
- **[Giai đoạn 2: Tuning & Optimization (Load Test 2)](./load-test-2-tuning/README.md)**
  - Trạng thái: **Đã hoàn thành**.
  - Mục tiêu: Kiểm chứng hiệu quả của Connection Pool Tuning, Read Replicas và Caching.

## 5. Kiến trúc Hệ thống (Target Architecture)

Chi tiết kiến trúc hệ thống đích (Target Architecture) sau khi áp dụng Module A được mô tả đầy đủ tại tài liệu chính:

👉 **[Xem Tài liệu Kiến trúc Hệ thống (System Architecture)](../ARCHITECTURE.md)**

### Luồng Đặt xe (Booking Flow) - Asynchronous

1.  **Client** -> `POST /trips` -> **TripService**
2.  **TripService** -> Push Message -> **SQS**
3.  **TripService** -> `202 Accepted` -> **Client**
4.  **DriverService** (Worker) -> Poll Message -> **SQS**
5.  **DriverService** -> Find Drivers (Redis Geo) -> Notify Driver
