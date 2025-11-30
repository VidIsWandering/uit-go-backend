# Kế hoạch Thực hiện Module A: Scalability & Performance

Tài liệu này phác thảo lộ trình chuyển đổi hệ thống UIT-Go sang kiến trúc Hyper-scale, tập trung vào việc giải quyết các bài toán về hiệu năng và khả năng mở rộng.

## 1. Phân tích & Thiết kế Kiến trúc (Architecture Analysis & Design)

Mục tiêu: Xác định các điểm nghẽn (bottlenecks) tiềm tàng và đề xuất giải pháp kiến trúc phù hợp.

### Các Quyết định Kiến trúc (ADRs)

Chúng ta tập trung vào 3 trụ cột chính để đạt Hyper-scale:

1.  **Asynchronous Processing (ADR-001)**: Giải quyết vấn đề "Temporal Coupling" và "Flash Crowd" bằng AWS SQS.
2.  **Read Scalability (ADR-002)**: Giải quyết vấn đề "Read-Heavy" bằng Read Replicas và mô hình CQRS Lite.
3.  **Centralized Caching (ADR-003)**: Giải quyết vấn đề "High Frequency Access" bằng Redis Cluster.
4.  **Concurrency Control (ADR-005)**: Giải quyết vấn đề "Race Condition" khi đặt xe bằng Optimistic Locking.

## 2. Hiện thực hóa (Implementation)

Mục tiêu: Chuyển đổi mã nguồn và hạ tầng để hỗ trợ kiến trúc mới.

### Infrastructure (Terraform)

- [x] Provision SQS Queue (Standard) & DLQ.
- [x] Provision ElastiCache (Redis) Cluster.
- [x] Provision RDS Read Replicas (PostgreSQL).
- [x] Cấu hình Auto Scaling cho ECS Services (ADR-004).

### Application Code

- [x] **TripService (Producer)**: Tách luồng đặt xe, gửi message vào SQS.
- [x] **DriverService (Consumer)**: Implement Worker xử lý message tìm tài xế.
- [x] **UserService**: Implement Caching Layer (@Cacheable) cho User Profile.
- [x] **TripService**: Implement Optimistic Locking (@Version) cho Trip entity.

## 3. Chiến lược Kiểm chứng (Verification Strategy)

Chúng ta chia quá trình kiểm chứng thành 2 giai đoạn để đo lường hiệu quả của từng nhóm giải pháp.

### Giai đoạn 1: Xác thực Kiến trúc (Architecture Verification)

_Mục tiêu: Chứng minh tính đúng đắn (Correctness) và khả năng chịu lỗi (Resilience) của kiến trúc Event-Driven._

- **Kịch bản**: Spike Test (Mô phỏng lượng đặt xe tăng đột biến trong thời gian ngắn).
- **Trọng tâm đo lường**:
  - **Success Rate**: Tỷ lệ đặt xe thành công (không bị 500 Error).
  - **Queue Depth**: Khả năng hấp thụ traffic của SQS.
  - **Data Consistency**: Đảm bảo dữ liệu User trong Cache khớp với DB (sau khi fix Cache Eviction).

### Giai đoạn 2: Tối ưu hóa & Benchmarking (Optimization)

_Mục tiêu: Đẩy hiệu năng (Throughput/RPS) lên mức cực đại._

- **Các kỹ thuật Tuning áp dụng**:

  1.  **Database Scaling**: Kích hoạt Read/Write Splitting (RoutingDataSource) để tận dụng Read Replicas.
  2.  **Connection Pooling**: Tinh chỉnh HikariCP (max-lifetime, idle-timeout) để giảm overhead kết nối.
  3.  **SQS Batching**: Cấu hình Consumer đọc/xử lý theo lô (Batch Size = 10) để giảm I/O.
  4.  **Database Indexing**: Tối ưu Index cho các cột hay truy vấn (`driver_id`, `status`).

- **So sánh**: Lập bảng so sánh RPS và Latency giữa Giai đoạn 1 (Baseline) và Giai đoạn 2 (Optimized) để đưa vào Báo cáo.

## 4. Sản phẩm Bàn giao (Deliverables)

- **Source Code**: Đã refactor theo kiến trúc Microservices + Event-Driven.
- **Infrastructure Code**: Terraform modules hoàn chỉnh.
- **Documentation**:
  - Hệ thống ADRs (001-005) phản ánh thiết kế đích.
  - Báo cáo phân tích Trade-off và Kết quả Load Test.
