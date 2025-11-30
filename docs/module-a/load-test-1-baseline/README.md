# Kết quả Load Test Lần 1 (Baseline)

Thư mục này chứa các minh chứng (evidence) cho đợt kiểm thử tải đầu tiên (Baseline) nhằm xác định hiện trạng và điểm nghẽn của hệ thống trước khi tối ưu hóa.

## Cấu trúc thư mục

Vui lòng đặt các file minh chứng vào các thư mục tương ứng như sau:

### 1. Spike Test (Kiểm thử khả năng chịu tải đột ngột)

Thư mục: `spike-test/`

- **`grafana-client-side.png`**: Biểu đồ VUs, RPS, Latency (Góc nhìn từ k6).
- **`grafana-server-side.png`**: Biểu đồ CPU, RAM của các Service.
- **`grafana-database-side.png`**: Biểu đồ Connection Pool (Active/Idle/Pending).
- **`terminal-output.txt`**: Log kết quả chạy từ terminal.

### 2. Stress Test (Kiểm thử giới hạn chịu đựng)

Thư mục: `stress-test/`

- **`grafana-client-side.png`**: Biểu đồ VUs, RPS, Latency (Góc nhìn từ k6).
- **`grafana-server-side.png`**: Biểu đồ CPU, RAM của các Service.
- **`grafana-database-side.png`**: Biểu đồ Connection Pool (Active/Idle/Pending).
- **`terminal-output.txt`**: Log kết quả chạy từ terminal.

## Tóm tắt Kết quả (Sơ bộ)

### Spike Test (100 VUs)

- **Mục tiêu**: Chứng minh khả năng hấp thụ traffic của Queue.
- **Kết quả**:
  - **Latency**: `p(95) = 1.94s` (Vượt ngưỡng 500ms).
  - **Error Rate**: `0.00%` (Hệ thống không sập, Queue hoạt động tốt).
  - **RPS**: ~29 req/s.
  - **Kết luận**: Hệ thống chịu được tải đột ngột nhưng phản hồi chậm do chưa tối ưu.

### Stress Test (500 VUs)

- **Mục tiêu**: Tìm điểm gãy (Breaking Point).
- **Kết quả**:
  - **Latency**: `p(95) = 6.78s` (Rất cao, vượt xa ngưỡng 2s).
  - **Error Rate**: `0.04%` (Xuất hiện 5 lỗi `connection reset by peer`).
  - **RPS**: Bão hòa ở mức ~56 req/s.
  - **Bottleneck**: Database Connection Pool (Pending Connections tăng cao, gây timeout ở tầng mạng).
  - **Capacity**: Hệ thống bắt đầu suy giảm nghiêm trọng (degrade) khi vượt quá 300 VUs.
