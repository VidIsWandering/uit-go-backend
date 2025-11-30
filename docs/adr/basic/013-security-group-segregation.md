# ADR 013: Phân tách Security Group (Security Group Segregation)

## Bối cảnh

Trong quá trình triển khai hạ tầng ban đầu, để đơn giản hóa việc kết nối, các tài nguyên thường được gán các Security Group (SG) có quy tắc quá mở (ví dụ: cho phép toàn bộ traffic trong VPC hoặc từ 0.0.0.0/0).

Tuy nhiên, khi chuẩn bị cho môi trường Production và Module A (Scalability), việc để SG quá mở tạo ra rủi ro bảo mật lớn (Lateral Movement - tấn công lan truyền). Nếu một container bị chiếm quyền, kẻ tấn công có thể truy cập trực tiếp vào Database hoặc các service khác mà không gặp trở ngại.

## Quyết định

Áp dụng nguyên tắc **Least Privilege** (Đặc quyền tối thiểu) cho Security Groups bằng cách phân tách và xâu chuỗi (Chaining) các SG.

Cụ thể, chúng ta thiết lập 4 lớp SG riêng biệt:

1.  **ALB SG (`alb_sg`)**:

    - Inbound: Cho phép HTTP (80) từ Internet (`0.0.0.0/0`).
    - Outbound: Chỉ cho phép traffic đến **App SG**.

2.  **App/ECS SG (`ecs_tasks_sg`)**:

    - Inbound: **CHỈ** cho phép traffic từ **ALB SG** trên port ứng dụng (8081, 8082, 8089). Từ chối mọi truy cập trực tiếp từ Internet.
    - Outbound: Cho phép traffic đến **Database SG** và Internet (để pull image/gọi API ngoài).

3.  **Database SG (`db_sg`)**:

    - Inbound: **CHỈ** cho phép traffic từ **App SG** trên port PostgreSQL (5432).
    - Outbound: Deny All (hoặc hạn chế tối đa).

4.  **Redis SG (`redis_sg`)**:
    - Inbound: **CHỈ** cho phép traffic từ **App SG** trên port Redis (6379).

## Lý do lựa chọn

1.  **Defense in Depth (Phòng thủ chiều sâu)**: Ngay cả khi kẻ tấn công vượt qua được tường lửa mạng (NACL), họ vẫn bị chặn bởi Security Group.
2.  **Isolation**: Cô lập các thành phần. Database không bao giờ nhận request trực tiếp từ ALB hay Internet.
3.  **Compliance**: Tuân thủ các tiêu chuẩn bảo mật cơ bản (như AWS Well-Architected Framework).

## Hệ quả

### Tích cực

- **Tăng cường bảo mật**: Giảm thiểu bề mặt tấn công (Attack Surface).
- **Kiểm soát rõ ràng**: Dễ dàng audit xem ai được phép gọi ai.

### Tiêu cực

- **Phức tạp quản lý**: Cần khai báo nhiều resource `aws_security_group` và `aws_security_group_rule` trong Terraform.
- **Khó Debug**: Nếu cấu hình sai (quên allow port), service sẽ không kết nối được với nhau (Connection Timeout), cần kiểm tra kỹ logs và SG rules.

## Trạng thái

Accepted
