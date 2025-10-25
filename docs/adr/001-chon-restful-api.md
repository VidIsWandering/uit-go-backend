# ADR 001: Lựa chọn RESTful API cho giao tiếp Microservice

**Trạng thái:** Đã quyết định

## Bối cảnh

Hệ thống UIT-Go được xây dựng trên kiến trúc microservices. Các service (UserService, TripService, DriverService) cần giao tiếp với nhau.

## Các lựa chọn đã cân nhắc

1.  **gRPC:**
    * **Ưu điểm:** Hiệu năng cao (sử dụng Protobuf), phù hợp cho giao tiếp nội bộ (internal service-to-service).
    * **Nhược điểm:** Cần file `.proto` để định nghĩa, phức tạp hơn khi debug, hệ sinh thái (Postman, browser) hỗ trợ không trực tiếp bằng REST.

2.  **RESTful API (với JSON):**
    * **Ưu điểm:** Phổ biến, đơn giản, hệ sinh thái mạnh (OpenAPI, Postman, ...), dễ dàng debug.
    * **Nhược điểm:** Hiệu năng (độ trễ, kích thước payload) cao hơn gRPC.

## Quyết định

Chúng ta quyết định chọn **RESTful API (với JSON)** cho toàn bộ giao tiếp service-to-service.

## Lý do & Đánh đổi (Trade-offs)

Đây là một quyết định đánh đổi có chủ đích, ưu tiên **Tốc độ Phát triển (Velocity)** và **Tính dễ Vận hành/Debug (Operability)** hơn là **Hiệu năng thô (Raw Performance)**.

* **Ưu điểm (Chúng ta có):**
    * **Hệ sinh thái:** Có thể sử dụng ngay lập tức các công cụ như Postman/Insomnia để kiểm thử từng service độc lập mà không cần tạo client.
    * **Tính đơn giản:** Dễ dàng cho cả hai thành viên trong nhóm nhanh chóng nắm bắt và triển khai API.
    * **Dễ Debug:** Dữ liệu JSON con người có thể đọc được (human-readable), giúp việc debug luồng giao tiếp giữa các service nhanh hơn.
    * **Tính tương thích Đa ngôn ngữ:** Lựa chọn này cho phép Role A (Java) và Role B (Node.js) giao tiếp dễ dàng mà không cần thư viện client phức tạp.
* **Nhược điểm (Chúng ta chấp nhận):**
    * **Hiệu năng:** Chúng ta chấp nhận overhead (độ trễ, kích thước payload) của HTTP/JSON sẽ cao hơn so với gRPC.

Khi hệ thống phát triển và yêu cầu về performance ở các service nội bộ tăng cao, chúng ta có thể xem xét chuyển đổi các giao tiếp *nội bộ quan trọng* sang gRPC trong tương lai.