# ADR 010: Tái cấu trúc (Refactor) Terraform sang Modules

**Trạng thái:** Đã quyết định

## Bối cảnh

File `main.tf` ban đầu chứa định nghĩa cho toàn bộ 40+ tài nguyên hạ tầng (VPC, Subnets, RDS, ElastiCache, Secrets Manager, ECS, ALB, ECR...). File này trở nên rất dài (hơn 500 dòng), khó đọc, khó bảo trì và khó tìm kiếm khi cần sửa đổi.

## Các lựa chọn đã cân nhắc

1.  **Giữ nguyên 1 file `main.tf` (Monolithic):**
    * **Ưu điểm:** Đơn giản ban đầu, tất cả code ở một nơi.
    * **Nhược điểm:** Vi phạm nguyên tắc "Tách biệt các mối quan tâm" (Separation of Concerns). Rất khó bảo trì, khó tìm lỗi, và không thể tái sử dụng.

2.  **Tái cấu trúc sang Local Modules:**
    * **Ưu điểm:** Phân chia code theo chức năng (ví dụ: `network`, `database`, `ecs`). File `main.tf` (gốc) trở nên gọn gàng, đọc như một bản tóm tắt kiến trúc. Dễ dàng quản lý và bảo trì từng phần.
    * **Nhược điểm:** Tốn công sức refactor ban đầu (tạo file, di chuyển code, chạy `terraform state mv` để di chuyển trạng thái).

## Quyết định

Chúng ta quyết định chọn **Tái cấu trúc sang Local Modules** (Lựa chọn 2).

## Lý do & Đánh đổi (Trade-offs)

Đây là quyết định ưu tiên **Tính bảo trì (Maintainability)** và **Tính rõ ràng (Clarity)** về lâu dài hơn là sự thuận tiện ban đầu.

* **Ưu điểm (Chúng ta có):** Mã nguồn IaC được tổ chức sạch sẽ, dễ hiểu. Dễ dàng nâng cấp hoặc sửa đổi từng phần (ví dụ: chỉ cần vào module `database` để sửa CSDL) mà không ảnh hưởng đến các phần khác.
* **Nhược điểm (Chúng ta chấp nhận):** Chúng ta chấp nhận bỏ ra thời gian ban đầu để thực hiện refactor và chạy các lệnh `terraform state mv` phức tạp để di chuyển trạng thái mà không phá hủy hạ tầng.