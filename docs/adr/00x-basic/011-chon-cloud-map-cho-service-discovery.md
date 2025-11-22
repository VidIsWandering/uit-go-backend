# ADR 011: Lựa chọn AWS Cloud Map cho Giao tiếp Nội bộ (Service Discovery)

**Trạng thái:** Đã quyết định

## Bối cảnh

Trong môi trường ECS Fargate, các container (Tasks) được gán địa chỉ IP động mỗi khi chúng khởi động. Điều này tạo ra một vấn đề: Làm thế nào `TripService` (Java) có thể biết được địa chỉ IP hiện tại của `UserService` hoặc `DriverService` để gọi API nội bộ? Các URL tạm thời (`http://user-service.local:8080`) sẽ không hoạt động.

## Các lựa chọn đã cân nhắc

1.  **Gọi qua ALB Public:** `TripService` gọi vào DNS name công cộng của ALB.
    * **Nhược điểm:** Rất tệ về hiệu năng và chi phí. Traffic đi "vòng" (hairpinning) ra Internet rồi quay lại VPC, gây trễ và tốn chi phí NAT Gateway/ALB.

2.  **Sử dụng ALB Nội bộ (Internal ALB):** Tạo một ALB thứ hai, chỉ truy cập được bên trong VPC.
    * **Ưu điểm:** Giải pháp tốt, cân bằng tải nội bộ.
    * **Nhược điểm:** Tốn chi phí cho một ALB nữa. Vẫn cần cấu hình Target Group và Listener Rules.

3.  **Sử dụng AWS Cloud Map (Service Discovery):**
    * **Ưu điểm:** Giải pháp "chính chủ" (native) của AWS cho ECS. Chúng ta tạo một "namespace" (ví dụ: `uit-go.local`). ECS tự động đăng ký địa chỉ IP của các Task (ví dụ: `driver-service.uit-go.local`) vào đó. `TripService` chỉ cần gọi đến URL nội bộ này.
    * **Nhược điểm:** Thêm một chút phức tạp ban đầu vào cấu hình Terraform (thêm `aws_service_discovery_service` và `service_registries`).

## Quyết định

Chúng ta quyết định chọn **AWS Cloud Map (Service Discovery)** (Lựa chọn 3) để xử lý giao tiếp nội bộ.

## Lý do & Đánh đổi (Trade-offs)

Đây là quyết định ưu tiên **Hiệu năng (Performance)** và **Kiến trúc Cloud-Native chuẩn** hơn là sự đơn giản (tránh dùng Lựa chọn 1).

* **Ưu điểm (Chúng ta có):**
    * Traffic giao tiếp nội bộ đi thẳng giữa các service (container-to-container) bên trong VPC, cho độ trễ thấp nhất.
    * Hệ thống tự động cập nhật IP khi Task (container) khởi động lại hoặc scale.
* **Nhược điểm (Chúng ta chấp nhận):** Chúng ta chấp nhận thêm tài nguyên Terraform (`aws_service_discovery_private_dns_namespace`) và cấu hình `service_registries` trong `aws_ecs_service`.