# ADR 007: Đặt Cơ sở dữ liệu trong Private Subnets

**Trạng thái:** Đã quyết định

## Bối cảnh

Hệ thống UIT-Go sử dụng 3 CSDL (2 PostgreSQL RDS, 1 ElastiCache Redis). Khi thiết kế VPC, chúng ta cần quyết định nên đặt các CSDL này vào public subnets hay private subnets.

## Các lựa chọn đã cân nhắc

1.  **Đặt CSDL trong Public Subnets:** Cấp cho CSDL địa chỉ IP công cộng và cho phép truy cập trực tiếp từ Internet (vẫn cần Security Group).
    * **Ưu điểm:** Dễ dàng kết nối để debug từ máy local.
    * **Nhược điểm:** **Rủi ro bảo mật cực lớn.** Mở CSDL ra Internet làm tăng bề mặt tấn công một cách không cần thiết.

2.  **Đặt CSDL trong Private Subnets:** CSDL chỉ có địa chỉ IP riêng tư, không thể truy cập trực tiếp từ Internet. Chỉ các tài nguyên khác bên trong cùng VPC (ví dụ: các container ứng dụng ECS) mới có thể kết nối (thông qua Security Group).
    * **Ưu điểm:** **Bảo mật cao.** Giảm thiểu bề mặt tấn công theo nguyên tắc "defense-in-depth".
    * **Nhược điểm:** Khó khăn hơn khi cần debug CSDL trực tiếp từ máy local (cần thiết lập Bastion Host hoặc VPN).

## Quyết định

Chúng ta quyết định **Đặt toàn bộ CSDL (RDS và ElastiCache) trong Private Subnets** (Lựa chọn 2).

Chúng ta đã hiện thực hóa điều này bằng cách tạo các `aws_db_subnet_group` và `aws_elasticache_subnet_group` chỉ tham chiếu đến các `aws_subnet` private (`private_a`, `private_b`). Đồng thời, các `aws_db_instance` được cấu hình với `publicly_accessible = false`.

## Lý do & Đánh đổi (Trade-offs)

Đây là quyết định ưu tiên **Bảo mật (Security)** hơn là **Sự thuận tiện khi Debug**.

* **Ưu điểm (Chúng ta có):**
    * Giảm thiểu đáng kể nguy cơ CSDL bị tấn công từ bên ngoài.
    * Tuân thủ nguyên tắc đặc quyền tối thiểu (Least Privilege) cho kết nối mạng.
* **Nhược điểm (Chúng ta chấp nhận):** Chúng ta chấp nhận rằng việc gỡ lỗi CSDL trực tiếp sẽ khó khăn hơn. Nếu cần, chúng ta sẽ xem xét thiết lập Bastion Host trong tương lai.