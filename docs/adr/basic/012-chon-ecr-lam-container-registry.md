# ADR 012: Lựa chọn AWS ECR làm Kho chứa Container (Container Registry)

**Trạng thái:** Đã quyết định

## Bối cảnh

Các ứng dụng microservices (Java, Node.js) của chúng ta cần được đóng gói thành Docker images. ECS Fargate cần một nơi để "kéo" (pull) các image này về để chạy.

## Các lựa chọn đã cân nhắc

1.  **Docker Hub:** Kho chứa public/private phổ biến nhất.
    * **Ưu điểm:** Phổ biến, dễ sử dụng.
    * **Nhược điểm:** Tốc độ pull image từ AWS sang có thể chậm hơn. Phức tạp hơn về bảo mật (ECS cần credentials để pull private image từ Docker Hub).

2.  **AWS ECR (Elastic Container Registry):** Dịch vụ registry "chính chủ" (native) của AWS.
    * **Ưu điểm:** **Bảo mật & Tích hợp IAM:** Tích hợp hoàn hảo với `ECS Task Execution Role`. Role này (mà chúng ta đã tạo) tự động có quyền pull image từ ECR trong cùng tài khoản mà không cần quản lý thêm bất kỳ token hay mật khẩu nào.
    * **Hiệu năng:** Image được lưu trữ gần với ECS (cùng Region), giúp tăng tốc độ kéo image và khởi động Task.
    * **Nhược điểm:** Gây ra "vendor lock-in" (khóa nhà cung cấp) ở mức độ registry.

## Quyết định

Chúng ta quyết định chọn **AWS ECR** (Lựa chọn 2) làm kho chứa container cho dự án. (Chúng ta đã hiện thực hóa bằng tài nguyên `aws_ecr_repository`).

## Lý do & Đánh đổi (Trade-offs)

Đây là quyết định ưu tiên **Bảo mật Tích hợp (Integrated Security)** và **Hiệu năng (Performance)** hơn là **Tính Độc lập (Vendor Agnosticism)**.

* **Ưu điểm (Chúng ta có):** Quy trình xác thực để pull image diễn ra tự động và an toàn qua IAM Role. Tốc độ khởi động container nhanh hơn.
* **Nhược điểm (Chúng ta chấp nhận):** Chúng ta chấp nhận rằng các image này bị khóa trong hệ sinh thái AWS.