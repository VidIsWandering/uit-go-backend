# ADR 001: Chuyển đổi sang Kiến trúc Bất đồng bộ (Asynchronous Architecture) cho Luồng Đặt xe

## Bối cảnh

Trong kiến trúc Synchronous cũ, API đặt xe (`POST /trips`) gọi trực tiếp sang `DriverService`.

- **Vấn đề**:
  1.  **Temporal Coupling**: `TripService` và `DriverService` phải cùng sống tại một thời điểm. Nếu `DriverService` chậm, `TripService` cũng chậm theo.
  2.  **Load Sensitivity**: Khi lượng request tăng đột biến (Flash Crowd), `DriverService` dễ bị quá tải, gây hiệu ứng dây chuyền (Cascading Failure) làm sập toàn bộ hệ thống.

## Quyết định

Chuyển sang kiến trúc **Event-Driven** sử dụng **AWS SQS (Standard Queue)**.

### 1. Mô hình Producer-Consumer

- **TripService (Producer)**: Nhận request, validate, lưu DB trạng thái `PENDING`, đẩy event `TripCreated` vào SQS, và trả về `202 Accepted` ngay lập tức.
- **DriverService (Consumer)**: Worker process đọc message từ SQS và thực hiện logic tìm tài xế (Matching).

### 2. Tại sao chọn SQS Standard (thay vì FIFO)?

- **Throughput**: SQS Standard hỗ trợ throughput gần như vô hạn. FIFO bị giới hạn (tối đa 3,000 msg/s nếu dùng batching), có thể trở thành điểm nghẽn trong kịch bản Hyper-scale.
- **Trade-off**: Standard Queue không đảm bảo thứ tự tuyệt đối và có thể gửi lặp (At-least-once delivery).
  - _Giải pháp_: Thiết kế Consumer (`DriverService`) phải **Idempotent** (xử lý lặp lại không gây lỗi). Sử dụng `TripID` làm khóa để kiểm tra trùng lặp.

### 3. Cơ chế Backpressure & Fault Tolerance

- **Load Leveling**: Queue đóng vai trò bộ đệm (buffer), giúp san phẳng các đợt tải đỉnh điểm. Worker có thể xử lý theo tốc độ của nó mà không bị "ngập lụt".
- **Dead Letter Queue (DLQ)**: Các message xử lý lỗi nhiều lần sẽ được đẩy vào DLQ để debug, đảm bảo không làm tắc nghẽn luồng chính và không mất dữ liệu nghiệp vụ.

## Hệ quả

### Tích cực

- **High Availability**: Hệ thống vẫn nhận đơn đặt xe ngay cả khi module tìm tài xế đang bảo trì hoặc gặp sự cố.
- **Scalability**: Có thể tăng số lượng Worker (`DriverService`) độc lập với `TripService` để tăng tốc độ xử lý queue.
- **Resilience**: Ngăn chặn lỗi dây chuyền.

### Tiêu cực

- **Complexity**: Phải xử lý tính Idempotency và Eventual Consistency. Client phải thay đổi cách tương tác (Polling hoặc WebSocket để nhận kết quả).
- **Latency**: Độ trễ End-to-End tăng nhẹ, nhưng đổi lại là sự ổn định tuyệt đối của hệ thống.

## Trạng thái

Accepted
