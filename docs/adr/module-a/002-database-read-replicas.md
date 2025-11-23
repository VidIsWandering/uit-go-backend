# ADR 002: Chiến lược Mở rộng Cơ sở dữ liệu (Database Read Scalability)

## Bối cảnh

Hệ thống UIT-Go có đặc thù **Read-Heavy** (Tỷ lệ Đọc/Ghi khoảng 80/20 hoặc 90/10).
Một instance Database duy nhất (Primary) sẽ nhanh chóng trở thành điểm nghẽn (Bottleneck) về I/O và CPU khi lượng người dùng tăng cao.

## Quyết định

Triển khai mô hình **Read Replicas** với **PostgreSQL** và áp dụng **CQRS Lite** ở tầng ứng dụng.

### 1. Kiến trúc Replication

- **Primary Instance**: Chuyên trách các thao tác **GHI** (INSERT, UPDATE, DELETE). Đảm bảo tính nhất quán dữ liệu (Strong Consistency).
- **Read Replicas**: Chuyên trách các thao tác **ĐỌC**. Dữ liệu được đồng bộ bất đồng bộ (Async Replication) từ Primary.

### 2. Xử lý Replication Lag (Thách thức của Hyper-scale)

Trong hệ thống phân tán, dữ liệu ở Replica luôn chậm hơn Primary một khoảng thời gian (Lag).

- **Vấn đề**: User vừa cập nhật hồ sơ (Ghi Primary), reload trang ngay lập tức (Đọc Replica) nhưng thấy dữ liệu cũ -> Trải nghiệm tồi (Stale Read).
- **Giải pháp**:
  - **Sticky Session / Write-Concern**: Với các luồng nhạy cảm (như sau khi Payment), ứng dụng sẽ chủ động đọc từ Primary hoặc Cache trong một khoảng thời gian ngắn.
  - **Chấp nhận Eventual Consistency**: Với các dữ liệu như "Vị trí tài xế trên bản đồ của khách", độ trễ vài giây là chấp nhận được.

## Hệ quả

### Tích cực

- **Performance**: Tăng throughput tổng thể của hệ thống lên nhiều lần bằng cách thêm Replica.
- **High Availability**: Nếu Primary gặp sự cố, cơ chế Failover sẽ tự động thăng cấp (promote) một Replica lên làm Primary mới, giảm thiểu thời gian downtime.

### Tiêu cực

- **Complexity**: Application code phải quản lý 2 connection pool (WriteDS và ReadDS) và logic chọn nguồn dữ liệu.
- **Cost**: Chi phí tăng tuyến tính theo số lượng Replica.

## Trạng thái

Accepted
