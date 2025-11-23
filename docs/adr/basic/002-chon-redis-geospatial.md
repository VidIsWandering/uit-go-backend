# ADR 002: Lựa chọn Redis Geospatial cho DriverService

**Trạng thái:** Đã quyết định

## Bối cảnh

`DriverService` có trách nhiệm quản lý vị trí của tài xế theo thời gian thực và cung cấp API để tìm kiếm các tài xế phù hợp ở gần. Đây là nghiệp vụ cốt lõi, ảnh hưởng trực tiếp đến trải nghiệm người dùng (thời gian chờ tìm xe) và đòi hỏi **độ trễ cực thấp**.

## Các lựa chọn đã cân nhắc

Chúng ta đã phân tích 3 hướng tiếp cận chính:

1.  **Redis (Geospatial):** Hướng "Ưu tiên tốc độ (Speed-first)". Dùng CSDL in-memory với các lệnh `GEOADD`/`GEOSEARCH` tích hợp sẵn.
2.  **DynamoDB (với Geohashing):** Hướng "Ưu tiên khả năng mở rộng và chi phí (Scale/Cost-first)". Yêu cầu logic geohashing phức tạp được hiện thực hóa ở tầng ứng dụng (Node.js).
3.  **PostgreSQL (với PostGIS):** Hướng "Ưu tiên sự đơn giản vận hành & Sức mạnh truy vấn". Tận dụng CSDL quan hệ hiện có với extension PostGIS.

## Quyết định

Chúng ta quyết định chọn hướng tiếp cận **"Ưu tiên tốc độ (Speed-first)"**, sử dụng **Redis với tính năng Geospatial**.

## Lý do & Đánh đổi (Trade-offs)

Đây là một quyết định đánh đổi có chủ đích, ưu tiên **Trải nghiệm Người dùng (User Experience)** hơn **Sự đơn giản Vận hành** và **Chi phí ở Quy mô lớn**.

* **Ưu điểm (Chúng ta có):**
    * **Độ trễ cực thấp:** Redis là CSDL in-memory, cho phép các thao tác `GEOADD` (cập nhật vị trí) và `GEOSEARCH` (tìm tài xế) diễn ra với tốc độ nhanh nhất có thể. Điều này là tối quan trọng cho nghiệp vụ tìm xe.
    * **Đơn giản khi triển khai (Logic-wise):** Các lệnh Geospatial đã được tích hợp sẵn. Service Node.js của chúng ta chỉ cần gọi lệnh thay vì tự implement logic geohashing phức tạp như khi dùng DynamoDB.

* **Nhược điểm (Chúng ta chấp nhận):**
    * **Phức tạp vận hành:** Chúng ta chấp nhận việc hệ thống phải quản lý thêm 1 loại CSDL nữa (Redis) bên cạnh 2 CSDL PostgreSQL của Role A.
    * **Hạn chế truy vấn:** Chúng ta chấp nhận rằng việc truy vấn phức tạp (ví dụ: "tìm tài xế 5-sao, gần nhất, *và* đang lái xe 7-chỗ") sẽ khó khăn hơn so với dùng PostGIS. Chúng ta sẽ giải quyết bài toán này ở tầng ứng dụng (Node.js) nếu cần.
    * **Chi phí:** RAM đắt hơn ổ đĩa, nên chi phí vận hành ElastiCache (Redis) có thể cao hơn RDS (Postgres) hoặc DynamoDB khi hệ thống lớn mạnh.