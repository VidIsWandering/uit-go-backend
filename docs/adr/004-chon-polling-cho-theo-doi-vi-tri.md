# ADR 004: Lựa chọn Polling cho tính năng Theo dõi Vị trí

**Trạng thái:** Đã quyết định

## Bối cảnh

Hành khách User Story 3 (Passenger US3) yêu cầu "thấy được vị trí của tài xế đang di chuyển trên bản đồ theo thời gian thực". Điều này đòi hỏi client (app hành khách) phải cập nhật vị trí liên tục.

## Các lựa chọn đã cân nhắc

1.  **WebSocket:** Giải pháp "real-time" thực thụ. Server (ví dụ: `DriverService`) sẽ "đẩy" (push) vị trí mới đến client ngay khi có.

    - **Ưu điểm:** Cập nhật tức thì, tiết kiệm tài nguyên mạng (không cần request liên tục).
    - **Nhược điểm:** Cực kỳ phức tạp để triển khai (quản lý kết nối, stateful), tốn nhiều thời gian phát triển Giai đoạn 1.

2.  **HTTP Polling (Định kỳ):** Client (app hành khách) sẽ chủ động gọi một API (ví dụ: `GET /trips/:id/driver-location`) mỗi 5 giây để lấy vị trí mới.
    - **Ưu điểm:** Cực kỳ đơn giản, nhanh chóng để hiện thực hóa. Hoàn toàn "stateless" và phù hợp với kiến trúc RESTful chúng ta đã chọn (ADR 001).
    - **Nhược điểm:** Có độ trễ (trễ tối đa 5 giây), tốn tài nguyên mạng (gọi liên tục).

## Quyết định

Chúng ta quyết định chọn **HTTP Polling** cho Giai đoạn 1.

Chúng ta đã hiện thực hóa điều này bằng cách Role B cung cấp API `GET /drivers/:id/location` và Role A cung cấp API `GET /trips/:id/driver-location` (để client gọi).

## Lý do & Đánh đổi (Trade-offs)

Đây là một quyết định đánh đổi có chủ đích, ưu tiên **Tốc độ Hoàn thành (Velocity)** hơn là **Tính thời gian thực (Real-time Efficiency)**.

- **Ưu điểm (Chúng ta có):** Chúng ta có thể hoàn thành 10 User Stories trong thời gian ngắn, sử dụng đúng stack công nghệ RESTful đã chọn.
- **Nhược điểm (Chúng ta chấp nhận):** Chúng ta chấp nhận trải nghiệm người dùng sẽ có độ trễ (vị trí cập nhật mỗi 5 giây) và hệ thống sẽ chịu tải request cao hơn (do polling). Đây là một "món nợ kỹ thuật" (technical debt) chấp nhận được cho Cột mốc 1.
