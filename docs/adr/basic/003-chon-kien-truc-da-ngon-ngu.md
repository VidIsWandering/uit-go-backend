# ADR 003: Lựa chọn Kiến trúc Đa ngôn ngữ (Polyglot)

**Trạng thái:** Đã quyết định

## Bối cảnh

Trong quá trình thành lập nhóm, chúng ta nhận thấy các thành viên có thế mạnh ở các hệ sinh thái công nghệ khác nhau. Cụ thể, Role A có chuyên môn sâu về **Java (Spring Boot)**, và Role B có chuyên môn về **Node.js (Express)**.

Đây là cơ hội để chúng ta áp dụng một trong những lợi ích lớn nhất của kiến trúc microservices: khả năng sử dụng công nghệ phù hợp nhất cho từng bài toán (right tool for the job) và cho phép các team phát triển độc lập.

## Các lựa chọn đã cân nhắc

1.  **Một Ngôn ngữ Chung (Monoglot):** Ép buộc cả hai thành viên dùng chung một ngôn ngữ (ví dụ: cả hai cùng dùng Java hoặc cả hai cùng dùng Node.js).
2.  **Đa ngôn ngữ (Polyglot):** Cho phép mỗi nhóm service (và thành viên) sử dụng công nghệ mà họ mạnh nhất và phù hợp nhất với nghiệp vụ.

## Quyết định

Chúng ta quyết định chọn kiến trúc **Đa ngôn ngữ (Polyglot)**.
* **`UserService` & `TripService` (Role A):** Sẽ được xây dựng bằng **Java (Spring Boot)**.
* **`DriverService` (Role B):** Sẽ được xây dựng bằng **Node.js (Express)**.

Hai hệ thống này sẽ giao tiếp với nhau qua **RESTful API** (như đã ghi lại trong ADR 001).

## Lý do & Đánh đổi (Trade-offs)

Đây là một quyết định đánh đổi có chủ đích, ưu tiên **Tốc độ Phát triển (Velocity)** và **Tối ưu hóa cho Từng Nhiệm Vụ (Task Optimization)** hơn là **Sự đồng nhất (Homogeneity)**.

* **Ưu điểm (Chúng ta có):**
    * **Tận dụng Thế mạnh:** Mỗi thành viên được làm việc với công nghệ mình mạnh nhất, giúp tăng tốc độ phát triển và chất lượng code.
    * **Công nghệ Phù hợp:** Chúng ta có thể dùng Java (mạnh về xử lý nghiệp vụ phức tạp, an toàn kiểu) cho `UserService` và `TripService`. Đồng thời, chúng ta dùng Node.js (mạnh về I/O bất đồng bộ, xử lý đồng thời cao) cho `DriverService` vốn yêu cầu xử lý lượng lớn request cập nhật vị trí thời gian thực.
    * **Mô phỏng thực tế:** Đây chính là cách các công ty công nghệ lớn vận hành, cho phép các team độc lập chọn stack công nghệ của mình.

* **Nhược điểm (Chúng ta chấp nhận):**
    * **Phức tạp Vận hành:** Chúng ta chấp nhận rằng việc vận hành, giám sát (monitoring) và xây dựng CI/CD cho hai hệ sinh thái (Java và Node.js) sẽ phức tạp hơn là chỉ dùng một.
    * **Chi phí "học hỏi":** Nếu có thành viên mới, họ có thể cần biết cả hai stack để bảo trì toàn bộ hệ thống, mặc dù trong phạm vi đồ án này điều đó không ảnh hưởng.