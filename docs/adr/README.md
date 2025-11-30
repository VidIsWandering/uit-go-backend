# Architectural Decision Records (ADR)

## Giới thiệu

Thư mục này lưu trữ các **Bản ghi Quyết định Kiến trúc (ADR)** của dự án UIT-Go.
Mỗi ADR là một bằng chứng cho quá trình tư duy thiết kế (Design Thinking) của nhóm, ghi lại không chỉ **kết quả** (chúng tôi chọn công nghệ gì) mà quan trọng hơn là **lý do** (tại sao chọn nó) và **các đánh đổi** (trade-offs) đã được cân nhắc kỹ lưỡng.

Việc duy trì ADR giúp chúng tôi:

1.  **Minh bạch hóa** các quyết định kỹ thuật.
2.  **Tránh tranh luận lặp lại** về các vấn đề đã được giải quyết.
3.  **Thể hiện tư duy System Engineer**: Luôn cân nhắc giữa Chi phí (Cost), Hiệu năng (Performance), Độ tin cậy (Reliability) và Tính khả thi (Feasibility).

## Danh mục Quyết định

### 🚀 Module A: Scalability & Performance (Giai đoạn 2 - Nâng cao)

Đây là các quyết định cốt lõi để chuyển đổi hệ thống sang kiến trúc **Hyper-scale**.

| ID                                                     | Tiêu đề                       | Trạng thái  | Tóm tắt                                                                                            |
| :----------------------------------------------------- | :---------------------------- | :---------- | :------------------------------------------------------------------------------------------------- |
| [001](./module-a/001-architecture-async-processing.md) | **Async Communication (SQS)** | ✅ Accepted | Chuyển từ REST đồng bộ sang SQS bất đồng bộ để chịu tải cao (High Throughput).                     |
| [002](./module-a/002-database-read-replicas.md)        | **Database Read Scalability** | ✅ Accepted | Sử dụng Read Replicas và CQRS Lite để giải quyết nút thắt cổ chai khi Đọc dữ liệu.                 |
| [003](./module-a/003-caching-strategy.md)              | **Centralized Caching**       | ✅ Accepted | Mở rộng Redis làm trung tâm Caching cho User Profile và Config.                                    |
| [004](./module-a/004-autoscaling-strategy.md)          | **Auto-scaling Strategy**     | ✅ Accepted | Chiến lược scale đa tầng (Compute & Storage) kết hợp Read Replicas để tối ưu chi phí và hiệu năng. |
| [005](./module-a/005-concurrency-control.md)           | **Concurrency Control**       | ✅ Accepted | Sử dụng Optimistic Locking để giải quyết Race Condition trong môi trường phân tán.                 |

### 🏗️ Core Infrastructure (Giai đoạn 1 - Nền tảng)

Các quyết định nền tảng để xây dựng "bộ xương" Microservices.

| ID                                                             | Tiêu đề                        | Trạng thái  | Tóm tắt                                                                        |
| :------------------------------------------------------------- | :----------------------------- | :---------- | :----------------------------------------------------------------------------- |
| [001](./basic/001-chon-restful-api.md)                         | **RESTful API**                | ✅ Accepted | Sử dụng chuẩn HTTP/JSON cho giao tiếp giữa Client và Backend.                  |
| [002](./basic/002-chon-redis-geospatial.md)                    | **Redis Geospatial**           | ✅ Accepted | Sử dụng Redis GEO để lưu trữ và truy vấn vị trí tài xế (tối ưu tốc độ).        |
| [003](./basic/003-chon-kien-truc-da-ngon-ngu.md)               | **Polyglot Architecture**      | ✅ Accepted | Kết hợp Java (Spring Boot) cho nghiệp vụ chính và Node.js cho tác vụ nhẹ.      |
| [004](./basic/004-chon-polling-cho-theo-doi-vi-tri.md)         | **Client Polling**             | ✅ Accepted | Sử dụng cơ chế Polling đơn giản để cập nhật vị trí thay vì WebSocket phức tạp. |
| [005](./basic/005-chon-terraform-de-quan-ly-ha-tang.md)        | **Terraform (IaC)**            | ✅ Accepted | Quản lý toàn bộ hạ tầng AWS bằng mã nguồn (Infrastructure as Code).            |
| [006](./basic/006-su-dung-secrets-manager-cho-mat-khau-rds.md) | **AWS Secrets Manager**        | ✅ Accepted | Lưu trữ và xoay vòng mật khẩu Database an toàn, tránh hard-code.               |
| [007](./basic/007-dat-csdl-trong-private-subnets.md)           | **Private Subnets**            | ✅ Accepted | Đặt Database và App Server trong mạng nội bộ, không lộ ra Internet.            |
| [008](./basic/008-chon-ecs-de-trien-khai-container.md)         | **AWS ECS**                    | ✅ Accepted | Sử dụng ECS làm trình điều phối Container (Container Orchestration).           |
| [009](./basic/009-chon-fargate-launch-type-cho-ecs.md)         | **AWS Fargate**                | ✅ Accepted | Chạy Container theo mô hình Serverless, giảm gánh nặng quản lý EC2.            |
| [010](./basic/010-refactor-terraform-sang-modules.md)          | **Modular Terraform**          | ✅ Accepted | Tổ chức code Terraform thành các modules tái sử dụng (Network, DB, ECS...).    |
| [011](./basic/011-chon-cloud-map-cho-service-discovery.md)     | **AWS Cloud Map**              | ✅ Accepted | Cơ chế Service Discovery nội bộ cho các Microservices.                         |
| [012](./basic/012-chon-ecr-lam-container-registry.md)          | **Amazon ECR**                 | ✅ Accepted | Kho lưu trữ Docker Image bảo mật và tích hợp sâu với ECS.                      |
| [013](./basic/013-security-group-segregation.md)               | **Security Group Segregation** | ✅ Accepted | Áp dụng nguyên tắc Least Privilege, phân tách SG cho từng lớp (ALB, App, DB).  |

## Cấu trúc của một ADR

Mỗi ADR tuân theo cấu trúc chuẩn:

1.  **Bối cảnh (Context)**: Vấn đề đang gặp phải là gì? Các ràng buộc là gì?
2.  **Quyết định (Decision)**: Chúng tôi chọn giải pháp nào?
3.  **Hệ quả (Consequences)**:
    - **Tích cực**: Lợi ích đạt được.
    - **Tiêu cực**: Các đánh đổi (Trade-offs) phải chấp nhận (ví dụ: tăng độ phức tạp, tăng chi phí, giảm tính nhất quán tức thì).
