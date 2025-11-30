# Báo cáo Tổng kết Dự án UIT-Go Backend

## 1. Tổng quan kiến trúc hệ thống

![Sơ đồ Kiến trúc AWS](images/architecture/aws-cloud-architecture.png)

Hệ thống UIT-Go Backend được xây dựng theo mô hình microservices, triển khai trên AWS với các thành phần chính:

- **ECS Fargate Cluster**: Chạy các service User, Trip, Driver.
- **RDS PostgreSQL (Primary & Read Replica)**: Lưu trữ dữ liệu giao dịch và phân tải đọc.
- **ElastiCache Redis**: Caching và xử lý dữ liệu vị trí.
- **Amazon SQS**: Hàng đợi bất đồng bộ cho luồng đặt chuyến.
- **ALB, NAT Gateway, Secrets Manager, CloudWatch, ECR**: Đảm bảo bảo mật, vận hành và quản lý hiện đại.

> Xem chi tiết tại: [ARCHITECTURE.md](ARCHITECTURE.md)

---

## 2. Phân tích Module chuyên sâu: Scalability & Performance (Module A)

### Cách tiếp cận

- **Async Processing**: Tách luồng đặt chuyến thành producer (Trip Service) và consumer (Driver Service) qua SQS.
- **Read Replicas**: Tối ưu hóa truy vấn đọc với RDS Read Replica, giảm tải cho Primary.
- **Centralized Caching**: Sử dụng Redis cho các truy vấn vị trí và profile có tần suất cao.
- **Auto Scaling**: Cấu hình scaling động cho ECS và RDS dựa trên CPU, Memory, Request Count.
- **Concurrency Control**: Áp dụng Optimistic Locking cho các thao tác nhận chuyến.

### Kết quả tuning & load test 2

> **[Phần này sẽ được cập nhật sau khi có kết quả load test 2 từ thành viên phụ trách.]**
>
> - Thống kê RPS, Latency, Success Rate trước/sau tuning.
> - So sánh hiệu quả từng giải pháp (SQS, Read Replica, Redis, Auto Scaling).

---

## 3. Tổng hợp các quyết định thiết kế & Trade-off (Quan trọng nhất)

| ADR         | Quyết định chính                                           | Lý do ưu tiên                     | Đánh đổi/Trade-off        |
| ----------- | ---------------------------------------------------------- | --------------------------------- | ------------------------- |
| ADR-001     | RESTful API                                                | Đơn giản, đa ngôn ngữ             | Overhead HTTP/JSON        |
| ADR-002     | Redis Geospatial                                           | Truy vấn vị trí cực nhanh         | Tốn RAM, chi phí Redis    |
| ADR-003     | Polyglot                                                   | Đúng tool cho đúng việc           | Phức tạp vận hành         |
| ADR-004     | Polling                                                    | Dễ triển khai                     | Độ trễ cập nhật           |
| ADR-005     | Terraform (IaC)                                            | Quản lý hạ tầng chuẩn             | Học cú pháp, debug khó    |
| ADR-006/007 | Secrets/Private Subnet                                     | Bảo mật tối đa                    | Debug phức tạp            |
| ADR-008/009 | ECS Fargate                                                | Không quản lý server              | Chi phí cao hơn EC2       |
| ADR-010     | Modular Terraform                                          | Dễ bảo trì, mở rộng               | Refactor tốn công         |
| ADR-011     | Cloud Map                                                  | Service Discovery nội bộ          | Tăng cấu hình             |
| ADR-012     | ECR                                                        | Registry bảo mật                  | Vendor lock-in            |
| ADR-013     | SG Segregation                                             | Least Privilege, Defense in Depth | Quản lý rules phức tạp    |
| Module A    | SQS, Read Replica, Redis, Auto Scaling, Optimistic Locking | Đạt hyper-scale                   | Tăng chi phí, độ phức tạp |

---

## 4. Thách thức & Bài học kinh nghiệm

### Thách thức

- **Giới hạn AWS**: Quota thấp, phải xin tăng hạn mức.
- **Quản lý IaC**: Refactor Terraform modules, debug resource dependencies.
- **Đồng bộ đa ngôn ngữ**: Mapping DTOs giữa Java và Node.js.
- **Tối ưu hiệu năng**: Phát hiện và xử lý bottleneck DB, tuning connection pool.

### Bài học kinh nghiệm

- **ADR giúp minh bạch hóa quyết định và tránh tranh luận lặp lại.**
- **IaC là chìa khóa cho vận hành hiện đại, nhưng cần đầu tư thời gian học và refactor.**
- **Kiến trúc tốt phải luôn cân bằng giữa hiệu năng, chi phí và độ phức tạp.**

---

## 5. Kết quả & Hướng phát triển

### Kết quả đã đạt được

- Hoàn thiện kiến trúc cloud-native, IaC 100%.
- Đáp ứng đầy đủ các user stories và yêu cầu phi chức năng.
- Đã thực hiện load test 1 (baseline), xác định bottleneck và lên kế hoạch tuning.

### Hướng phát triển tiếp theo

- **Cập nhật kết quả tuning & load test 2** (bổ sung sau).
- Triển khai CI/CD tự động hóa.
- Mở rộng sang các module Reliability, Security, Cost Optimization.
- Đề xuất tích hợp thêm các giải pháp observability (tracing, alerting).
