# ADR 008: Lựa chọn AWS ECS để Triển khai Container

**Trạng thái:** Đã quyết định

## Bối cảnh

Giai đoạn 1 của đồ án yêu cầu triển khai 3 container (UserService, TripService, DriverService) lên AWS. Tài liệu (Mục 3.2) gợi ý cân nhắc giữa việc tự quản lý trên EC2 hoặc sử dụng dịch vụ điều phối như ECS/EKS. Chúng ta cần chọn một chiến lược triển khai phù hợp.

## Các lựa chọn đã cân nhắc

1.  **Tự quản lý trên EC2:** Cài đặt Docker trên máy ảo EC2 và tự quản lý vòng đời container (chạy, dừng, cập nhật, logging, scaling...).
    * **Ưu điểm:** Linh hoạt tối đa, toàn quyền kiểm soát môi trường host.
    * **Nhược điểm:** Gánh nặng vận hành rất lớn, tốn thời gian thiết lập và bảo trì, khó scale tự động.

2.  **AWS ECS (Elastic Container Service):** Dịch vụ điều phối container được quản lý bởi AWS. AWS sẽ quản lý việc chạy, dừng, scale container dựa trên định nghĩa (Task Definition) chúng ta cung cấp. Có thể chạy trên EC2 (do AWS quản lý) hoặc Fargate (Serverless).
    * **Ưu điểm:** Giảm đáng kể gánh nặng vận hành, dễ dàng scale, tích hợp tốt với Load Balancer, CloudWatch. Có lựa chọn Fargate không cần quản lý server.
    * **Nhược điểm:** Ít linh hoạt hơn EC2 về cấu hình host. Cần học các khái niệm của ECS (Cluster, Service, Task Definition).

3.  **AWS EKS (Elastic Kubernetes Service):** Dịch vụ Kubernetes được quản lý bởi AWS.
    * **Ưu điểm:** Mạnh mẽ, tiêu chuẩn ngành, linh hoạt, tránh vendor lock-in ở mức độ ứng dụng Kubernetes.
    * **Nhược điểm:** Phức tạp nhất, learning curve cao nhất, thường là overkill cho hệ thống 3 microservices cơ bản trong Giai đoạn 1.

## Quyết định

Chúng ta quyết định chọn **AWS ECS (Elastic Container Service)** làm nền tảng triển khai container cho Giai đoạn 1. (Chúng ta sẽ xem xét dùng launch type Fargate để tối giản việc quản lý server).

## Lý do & Đánh đổi (Trade-offs)

Đây là quyết định ưu tiên **Giảm thiểu Gánh nặng Vận hành (Reduced Operational Burden)** và **Tốc độ Triển khai (Deployment Velocity)** hơn là **Linh hoạt Tối đa (Maximum Flexibility)**.

* **Ưu điểm (Chúng ta có):**
    * Chúng ta có thể tập trung vào việc định nghĩa *cách* ứng dụng chạy thay vì quản lý hạ tầng container.
    * Dễ dàng tích hợp với các dịch vụ AWS khác (ALB, CloudWatch) và thiết lập auto-scaling sau này.
    * Phù hợp với quy mô và độ phức tạp của Giai đoạn 1.
* **Nhược điểm (Chúng ta chấp nhận):**
    * Chúng ta chấp nhận mất đi một phần kiểm soát tầng OS so với việc dùng EC2 thuần túy.
    * Chúng ta chấp nhận việc học các khái niệm mới của ECS.