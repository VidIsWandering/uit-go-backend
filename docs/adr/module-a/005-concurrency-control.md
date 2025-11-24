# ADR 005: Kiểm soát Đồng thời (Concurrency Control) với Optimistic Locking

## Bối cảnh

Trong hệ thống đặt xe quy mô lớn (Hyper-scale), tình trạng **Race Condition** xảy ra thường xuyên.
Ví dụ điển hình:

1.  Hai hành khách cùng lúc đặt một chuyến xe (nếu hệ thống cho phép đi chung - Carpooling).
2.  Hai tài xế cùng lúc bấm "Nhận chuyến" cho cùng một chuyến đi.

Nếu không có cơ chế kiểm soát, dữ liệu sẽ bị ghi đè sai lệch (Lost Update), dẫn đến việc một chuyến đi có 2 tài xế hoặc trạng thái không nhất quán.

## Quyết định

Sử dụng cơ chế **Optimistic Locking** (Khóa lạc quan) thông qua tính năng `@Version` của JPA/Hibernate.

### Chi tiết Kỹ thuật

- Thêm cột `version` (kiểu Integer) vào các bảng quan trọng (`trips`, `users`).
- Khi đọc dữ liệu, ứng dụng đọc cả giá trị `version`.
- Khi cập nhật, câu lệnh SQL sẽ kiểm tra:
  ```sql
  UPDATE trips SET driver_id = ?, status = ?, version = version + 1
  WHERE id = ? AND version = ?
  ```
- Nếu `version` trong DB đã thay đổi (do transaction khác update trước), DB sẽ trả về số dòng update = 0.
- Ứng dụng sẽ ném ra ngoại lệ `OptimisticLockException`.

## Lý do lựa chọn

1.  **Performance**: Optimistic Locking không giữ khóa vật lý trên Database (như Pessimistic Locking `SELECT FOR UPDATE`). Điều này giúp duy trì Throughput cao và tránh Deadlock.
2.  **Phù hợp với Read-Heavy**: Trong hệ thống UIT-Go, tỷ lệ xung đột thực tế thấp so với tổng lượng truy cập, nên Optimistic Locking hiệu quả hơn Pessimistic Locking.

## Hệ quả

### Tích cực

- **Data Integrity**: Đảm bảo tuyệt đối tính toàn vẹn dữ liệu, không bao giờ có chuyện 2 tài xế nhận cùng 1 chuyến.
- **Scalability**: Không gây nghẽn Database do giữ lock lâu.

### Tiêu cực

- **Retry Logic**: Ứng dụng phải xử lý ngoại lệ `OptimisticLockException` (thường là báo lỗi cho người dùng "Chuyến đi đã có người nhận" hoặc tự động retry).

## Trạng thái

Accepted
