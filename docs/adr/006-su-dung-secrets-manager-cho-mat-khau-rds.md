# ADR 006: Sử dụng AWS Secrets Manager để Quản lý Mật khẩu RDS

**Trạng thái:** Đã quyết định

## Bối cảnh

Các CSDL PostgreSQL (RDS) cần có mật khẩu chủ (master password) để quản lý. Chúng ta cần một cách an toàn để tạo và cung cấp mật khẩu này khi định nghĩa hạ tầng bằng Terraform, tránh việc lưu trữ mật khẩu nhạy cảm trực tiếp trong mã nguồn.

## Các lựa chọn đã cân nhắc

1.  **Hardcode Mật khẩu trong Terraform:** Đặt mật khẩu dạng text trực tiếp trong file `.tf`.
    * **Nhược điểm:** Cực kỳ mất an toàn, vi phạm mọi nguyên tắc bảo mật. Mật khẩu sẽ bị lộ trên Git.

2.  **Sử dụng Biến Terraform (`.tfvars`):** Định nghĩa mật khẩu trong một file `.tfvars` riêng và thêm file này vào `.gitignore`.
    * **Ưu điểm:** Tốt hơn hardcode, mật khẩu không lên Git.
    * **Nhược điểm:** Vẫn yêu cầu người dùng tự tạo và quản lý mật khẩu mạnh. Khó khăn trong việc xoay vòng (rotate) mật khẩu.

3.  **Tích hợp AWS Secrets Manager:** Sử dụng resource `aws_secretsmanager_secret` và `random_password` của Terraform để yêu cầu AWS tự động tạo mật khẩu mạnh và lưu trữ an toàn trong Secrets Manager. Sau đó, cấu hình RDS (`manage_master_user_password = true`) để tự động lấy và sử dụng mật khẩu từ Secret đó.
    * **Ưu điểm:** An toàn nhất. Mật khẩu không bao giờ xuất hiện dạng text. AWS quản lý vòng đời mật khẩu.
    * **Nhược điểm:** Phức tạp hơn một chút khi thiết lập ban đầu trong Terraform.

## Quyết định

Chúng ta quyết định chọn **Tích hợp AWS Secrets Manager** (Lựa chọn 3).

## Lý do & Đánh đổi (Trade-offs)

Đây là quyết định ưu tiên **Bảo mật (Security)** hơn là **Sự đơn giản ban đầu**.

* **Ưu điểm (Chúng ta có):**
    * Mật khẩu CSDL được tạo ngẫu nhiên, mạnh và không bị lộ trong mã nguồn hay Git.
    * Tuân thủ các thực hành tốt nhất về bảo mật trên cloud.
* **Nhược điểm (Chúng ta chấp nhận):** Chúng ta chấp nhận mã Terraform phức tạp hơn một chút để quản lý thêm các resource `aws_secretsmanager_secret` và `random_password`.