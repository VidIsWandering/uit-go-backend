# ADR 009: Lựa chọn Fargate Launch Type cho AWS ECS

**Trạng thái:** Đã quyết định

## Bối cảnh

Sau khi quyết định sử dụng AWS ECS (ADR 008), chúng ta cần chọn phương thức ECS sẽ chạy các container (Launch Type). ECS cung cấp hai lựa chọn chính: EC2 Launch Type (tự quản lý máy chủ EC2) và Fargate Launch Type (serverless).

## Các lựa chọn đã cân nhắc

1.  **EC2 Launch Type:**
    * **Cách hoạt động:** Tạo và quản lý một nhóm máy ảo EC2 (Auto Scaling Group). ECS sẽ đặt các container lên các EC2 instance này.
    * **Ưu điểm:** Có thể rẻ hơn Fargate nếu ứng dụng chạy liên tục với tải cao/ổn định, linh hoạt hơn trong việc chọn loại instance, cấu hình OS.
    * **Nhược điểm:** **Gánh nặng vận hành lớn.** Phải tự quản lý EC2 cluster (vá lỗi OS, cập nhật AMI, scale EC2), cấu hình mạng phức tạp hơn.

2.  **Fargate Launch Type:**
    * **Cách hoạt động:** Chỉ cần định nghĩa CPU/Memory cho container. AWS Fargate sẽ tự động cung cấp hạ tầng tính toán để chạy nó mà không cần quản lý máy chủ.
    * **Ưu điểm:** **Đơn giản vận hành tối đa (Serverless).** Không cần lo lắng về việc quản lý EC2 instance. Trả tiền theo tài nguyên sử dụng thực tế (vCPU/Memory theo giây). Khởi động container nhanh.
    * **Nhược điểm:** Có thể đắt hơn EC2 nếu chạy 24/7 tải cao. Ít tùy chọn cấu hình hơn ở tầng host.

## Quyết định

Chúng ta quyết định chọn **Fargate Launch Type** cho việc triển khai ECS Services trong Giai đoạn 1.

Chúng ta đã hiện thực hóa điều này trong Terraform bằng cách chỉ định `requires_compatibilities = ["FARGATE"]` trong `aws_ecs_task_definition` và `launch_type = "FARGATE"` trong `aws_ecs_service`.

## Lý do & Đánh đổi (Trade-offs)

Đây là quyết định ưu tiên **Sự đơn giản Vận hành (Operational Simplicity)** và **Tốc độ Triển khai (Deployment Velocity)** hơn là **Tối ưu Chi phí Tiềm năng (Potential Cost Optimization)** hoặc **Linh hoạt Tối đa (Maximum Flexibility)**.

* **Ưu điểm (Chúng ta có):**
    * Giảm thiểu tối đa gánh nặng quản lý hạ tầng cho Giai đoạn 1.
    * Cho phép nhóm tập trung vào việc triển khai ứng dụng thay vì quản lý EC2 cluster.
    * Mô hình trả tiền theo sử dụng phù hợp với giai đoạn phát triển và demo.
* **Nhược điểm (Chúng ta chấp nhận):**
    * Chúng ta chấp nhận chi phí có thể cao hơn một chút so với việc tự tối ưu EC2 cluster (ví dụ: dùng Spot Instances).
    * Chúng ta chấp nhận mất đi khả năng tùy chỉnh sâu ở tầng OS/Network của EC2.