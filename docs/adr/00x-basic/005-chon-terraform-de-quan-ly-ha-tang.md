# ADR 005: Lựa chọn Terraform (IaC) để Quản lý Hạ tầng

**Trạng thái:** Đã quyết định

## Bối cảnh

Đồ án (Mục 3.2) yêu cầu hệ thống phải được triển khai trên AWS và sử dụng "Infrastructure as Code (IaC)". Chúng ta cần chọn một công cụ để định nghĩa hạ tầng (VPC, CSDL...).

## Các lựa chọn đã cân nhắc

1.  **ClickOps (Làm thủ công):** Đăng nhập vào AWS Console và click chuột để tạo VPC, RDS, ElastiCache.

    - **Ưu điểm:** Dễ dàng cho người mới bắt đầu, trực quan.
    - **Nhược điểm:** Không thể lặp lại, dễ gây lỗi, không thể quản lý phiên bản. Đi ngược lại yêu cầu của đồ án.

2.  **AWS CloudFormation:** Công cụ IaC "chính chủ" (native) của AWS (dùng JSON/YAML).

    - **Ưu điểm:** Tích hợp sâu nhất với AWS.
    - **Nhược điểm:** Cú pháp dài dòng. Gây ra **"vendor lock-in"** (khóa nhà cung cấp) - code CloudFormation này không thể dùng cho Google Cloud hay Azure.

3.  **Terraform:** Một công cụ IaC mã nguồn mở, "bất khả tri" về nền tảng (cloud-agnostic).
    - **Ưu điểm:** Định nghĩa hạ tầng bằng code (HCL) rõ ràng, dễ đọc. Quan trọng nhất là **tránh vendor lock-in**, cho phép tái sử dụng code nếu sau này muốn mở rộng sang multi-cloud.
    - **Nhược điểm:** Tốn thời gian học cú pháp (learning curve) ban đầu.

## Quyết định

Chúng ta quyết định chọn **Terraform** để hiện thực hóa yêu cầu IaC.

## Lý do & Đánh đổi (Trade-offs)

Đây là quyết định ưu tiên **Tính nhất quán (Consistency)** và **Tính linh hoạt chiến lược (Strategic Flexibility)**.

- **Ưu điểm (Chúng ta có):**
  - Hạ tầng được quản lý trên Git, đáp ứng yêu cầu "quản lý phiên bản như code".
  - Chúng ta xây dựng một kỹ năng có thể áp dụng cho mọi nền tảng cloud, **tránh bị khóa chặt (lock-in)** vào hệ sinh thái của riêng AWS.
- **Nhược điểm (Chúng ta chấp nhận):** Chúng ta chấp nhận sẽ tốn thời gian ban đầu (Phase 3) để học và viết code Terraform, thay vì dùng công cụ native có sẵn (CloudFormation).
