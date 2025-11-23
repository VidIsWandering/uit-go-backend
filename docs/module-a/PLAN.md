# Kế hoạch Thực hiện Module A: Scalability & Performance

Tài liệu này phác thảo lộ trình chuyển đổi hệ thống UIT-Go sang kiến trúc Hyper-scale.

## Giai đoạn 1: Thiết kế Kiến trúc (Architecture Design)

Mục tiêu: Chuyển đổi từ kiến trúc Monolithic/Synchronous sang Event-Driven/Asynchronous để tối đa hóa Throughput.

1.  **Phân tích & Ra quyết định (ADRs)**:

    - **ADR-001: Async Communication (SQS)**: Chuyển luồng đặt chuyến (Booking Flow) sang xử lý bất đồng bộ.
    - **ADR-002: Database Read Scalability**: Sử dụng Read Replicas để phân tải cho Database.
    - **ADR-003: Caching Strategy**: Áp dụng Redis Cache cho dữ liệu truy cập thường xuyên.
    - **ADR-004: Auto-scaling**: Thiết lập cơ chế tự động mở rộng cho Compute và Database.

2.  **Thiết kế Chi tiết**:
    - Sơ đồ luồng dữ liệu mới cho `TripService` -> `SQS` -> `DriverService`.
    - Cập nhật Terraform để provision SQS, ElastiCache, RDS Read Replicas.

## Giai đoạn 2: Hiện thực hóa (Implementation)

Mục tiêu: Điều chỉnh mã nguồn và hạ tầng theo thiết kế mới.

1.  **Infrastructure (Terraform)**:
    - Thêm module SQS.
    - Thêm module ElastiCache (Redis).
    - Cấu hình RDS Read Replica.
2.  **Application Code**:
    - **TripService**: Refactor API `POST /trips` để đẩy message vào SQS thay vì gọi trực tiếp DriverService.
    - **DriverService**: Implement SQS Consumer (Worker) để nhận yêu cầu tìm tài xế và xử lý.
    - Implement Caching Layer (Redis) cho User Profile và Driver Location.

## Giai đoạn 3: Kiểm chứng Thiết kế (Verification)

Mục tiêu: Chứng minh kiến trúc Event-Driven hoạt động đúng đắn và ổn định (Ready for Production).
_Môi trường thực hiện: Local (Docker Compose) - Mô phỏng môi trường Cloud._

1.  **Load Testing (Lần 1)**:
    - Thực hiện ngay sau khi hoàn thành Giai đoạn 2 (Implementation).
    - Mục tiêu: Đảm bảo hệ thống không bị lỗi (Functional Correctness) dưới tải cao và cơ chế Async hoạt động như mong đợi (không mất message).
    - Kịch bản: Spike Test (Mô phỏng lượng đặt xe tăng đột biến).

## Giai đoạn 4: Tối ưu hóa & Kiểm chứng Hiệu năng (Tuning & Benchmarking)

Mục tiêu: Tinh chỉnh các tham số để đạt hiệu năng cao nhất và so sánh kết quả.

1.  **Tuning**:

    - **Connection Pooling**: Tối ưu HikariCP (Java) / Pool Size (Node.js).
    - **Batch Processing**: Xử lý message theo lô (Batch) từ SQS để giảm IO.
    - **Index Tuning**: Review và tối ưu Index database.
    - **Redis Caching**: Tinh chỉnh TTL và Eviction Policy.

2.  **Load Testing (Lần 2)**:
    - Thực hiện sau khi đã Tuning.
    - Mục tiêu: Đo lường sự cải thiện về Throughput (RPS) và Latency so với Lần 1.
    - So sánh kết quả để đưa vào báo cáo (Report).
