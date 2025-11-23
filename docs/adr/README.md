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
| [003](./module-a/003-caching-strategy.md)              | **Caching & Geo-spatial**     | ✅ Accepted | Sử dụng Redis cho Caching và xử lý vị trí thời gian thực (Geo-spatial) thay vì PostGIS.            |
| [004](./module-a/004-autoscaling-strategy.md)          | **Auto-scaling Strategy**     | ✅ Accepted | Chiến lược scale đa tầng (Compute & Storage) kết hợp Read Replicas để tối ưu chi phí và hiệu năng. |

### 🏗️ Core Infrastructure (Giai đoạn 1 - Nền tảng)

Các quyết định nền tảng để xây dựng "bộ xương" Microservices.

| ID                                                             | Tiêu đề                               | Trạng thái  |
| :------------------------------------------------------------- | :------------------------------------ | :---------- |
| [001](./basic/001-chon-restful-api.md)                         | Chọn RESTful API cho giao tiếp cơ bản | ✅ Accepted |
| [002](./basic/002-chon-redis-geospatial.md)                    | Chọn Redis Geospatial (Speed-first)   | ✅ Accepted |
| [003](./basic/003-chon-kien-truc-da-ngon-ngu.md)               | Kiến trúc Đa ngôn ngữ (Polyglot)      | ✅ Accepted |
| [004](./basic/004-chon-polling-cho-theo-doi-vi-tri.md)         | Chọn Polling cho Client Tracking      | ✅ Accepted |
| [005](./basic/005-chon-terraform-de-quan-ly-ha-tang.md)        | Sử dụng Terraform (IaC)               | ✅ Accepted |
| [006](./basic/006-su-dung-secrets-manager-cho-mat-khau-rds.md) | Quản lý Secrets                       | ✅ Accepted |
| [007](./basic/007-dat-csdl-trong-private-subnets.md)           | Network Security (Private Subnets)    | ✅ Accepted |
| [008](./basic/008-chon-ecs-de-trien-khai-container.md)         | Chọn AWS ECS                          | ✅ Accepted |
| [009](./basic/009-chon-fargate-launch-type-cho-ecs.md)         | Chọn Fargate (Serverless Compute)     | ✅ Accepted |
| [010](./basic/010-refactor-terraform-sang-modules.md)          | Modular Terraform                     | ✅ Accepted |
| [011](./basic/011-chon-cloud-map-cho-service-discovery.md)     | Service Discovery                     | ✅ Accepted |
| [012](./basic/012-chon-ecr-lam-container-registry.md)          | Container Registry                    | ✅ Accepted |

## Cấu trúc của một ADR

Mỗi ADR tuân theo cấu trúc chuẩn:

1.  **Bối cảnh (Context)**: Vấn đề đang gặp phải là gì? Các ràng buộc là gì?
2.  **Quyết định (Decision)**: Chúng tôi chọn giải pháp nào?
3.  **Hệ quả (Consequences)**:
    - **Tích cực**: Lợi ích đạt được.
    - **Tiêu cực**: Các đánh đổi (Trade-offs) phải chấp nhận (ví dụ: tăng độ phức tạp, tăng chi phí, giảm tính nhất quán tức thì).
