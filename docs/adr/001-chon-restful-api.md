# ADR 001: Lựa chọn RESTful API cho giao tiếp Microservice

**Trạng thái:** Đã quyết định

## Bối cảnh

Hệ thống UIT-Go được xây dựng trên kiến trúc microservices và chúng ta đã quyết định áp dụng **kiến trúc đa ngôn ngữ (polyglot)**:
* **Role A (Nghiệp vụ):** `UserService` và `TripService` sẽ được xây dựng bằng **Java (Spring Boot)**.
* **Role B (Nền tảng/Dữ liệu):** `DriverService` sẽ được xây dựng bằng **Node.js (Express)**.

Do đó, chúng ta cần một tiêu chuẩn giao tiếp (communication standard) độc lập ngôn ngữ, cho phép hai hệ sinh thái này giao tiếp tin cậy.

## Các lựa chọn đã cân nhắc

1.  **gRPC:**
    * **Ưu điểm:** Hiệu năng cao (sử dụng Protobuf).
    * **Nhược điểm:** Yêu cầu file `.proto` và thư viện client/server-stub phải được tạo riêng cho cả Java và Node.js. Phức tạp hơn trong việc thiết lập và debug ban đầu.

2.  **RESTful API (với JSON):**
    * **Ưu điểm:** Là tiêu chuẩn phổ quát (lingua franca) của web. Mọi ngôn ngữ (Java, Node.js, Python, Go...) đều hỗ trợ xử lý HTTP và JSON một cách tự nhiên (native) mà không cần công cụ đặc thù.
    * **Nhược điểm:** Hiệu năng (độ trễ, kích thước payload) cao hơn gRPC.

## Quyết định

Chúng ta quyết định chọn **RESTful API (với JSON)** làm tiêu chuẩn giao tiếp chính cho toàn bộ hệ thống.

## Lý do & Đánh đổi (Trade-offs)

Đây là một quyết định kiến trúc có chủ đích để **hiện thực hóa kiến trúc Đa ngôn ngữ (Polyglot)**.

* **Ưu điểm (Chúng ta có):**
    * **Tính tương thích tuyệt đối:** Lựa chọn REST/JSON giải phóng chúng ta khỏi sự phụ thuộc vào ngôn ngữ. `TripService` (viết bằng Java) có thể gọi `DriverService` (viết bằng Node.js) một cách dễ dàng như bất kỳ API nào khác.
    * **Hệ sinh thái:** Có thể sử dụng ngay lập tức các công cụ chung (Postman, OpenAPI) để kiểm thử từng service độc lập, bất kể service đó được viết bằng ngôn ngữ gì.
    * **Tốc độ phát triển (Velocity):** Cả hai thành viên có thể làm việc song song ngay lập tức mà không cần lo lắng về việc đồng bộ file `.proto` hay các thư viện client.

* **Nhược điểm (Chúng ta chấp nhận):**
    * **Hiệu năng:** Chúng ta chấp nhận overhead (độ trễ, kích thước payload) của HTTP/JSON. Đây là cái giá hợp lý phải trả để đổi lấy sự linh hoạt tuyệt vời của kiến trúc đa ngôn ngữ.