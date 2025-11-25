# Hướng dẫn Kiểm chứng Thiết kế (Verification Guide)

Tài liệu này hướng dẫn chi tiết từng bước để thực hiện quy trình **Load Testing** nhằm kiểm chứng kiến trúc Microservices của dự án UIT-Go.

## Giai đoạn 1: Chuẩn bị Môi trường (Setup)

**Mục tiêu**: Đưa hệ thống về trạng thái sạch sẽ, sẵn sàng cho bài test.

1.  **Khởi động hệ thống**:
    Mở terminal tại thư mục gốc dự án, chạy lệnh:

    ```bash
    make restart
    ```

    _Chờ khoảng 30-60 giây để các service (đặc biệt là Database và Kafka/SQS) khởi động hoàn toàn._

2.  **Kiểm tra trạng thái**:
    Đảm bảo tất cả container đều ở trạng thái `Up` (hoặc `Healthy`):

    ```bash
    make status
    ```

3.  **Khởi tạo dữ liệu mẫu (Seeding)**:
    Tạo User test và 100 tài xế ảo trong Redis:

    ```bash
    make seed
    ```

    _Kết quả mong đợi: Thông báo "User created successfully" và "Drivers seeded successfully"._

4.  **Mở Dashboard Giám sát**:
    - Truy cập trình duyệt: `http://localhost:3001`
    - Đăng nhập: `admin` / `admin`
    - Vào mục **Dashboards** -> Chọn **UIT Go - Load Test Dashboard**.
    - Chỉnh thời gian (Time Range) ở góc trên bên phải thành **"Last 5 minutes"**.
    - Chỉnh chế độ tự động cập nhật (Auto Refresh) thành **"5s"**.

---

## Giai đoạn 2: Thực thi Kiểm thử (Execution)

### Kịch bản 1: Kiểm tra Ổn định (Average Load Test)

_Mục đích: Xác định hiệu năng nền (Baseline) của hệ thống._

1.  Tại terminal, chạy lệnh:
    ```bash
    make test-average
    ```
2.  Quan sát Dashboard Grafana trong 3 phút:
    - **RPS** có ổn định quanh mức 50 req/s không?
    - **Latency (p95)** có duy trì dưới 500ms không?
    - **Error Rate** có bằng 0 không?

### Kịch bản 2: Kiểm tra Chịu tải Đột biến (Spike Test) - **DÙNG ĐỂ QUAY DEMO**

_Mục đích: Chứng minh khả năng chịu tải cao nhờ kiến trúc Async._

1.  Chuẩn bị phần mềm quay màn hình (OBS, Windows Game Bar...).
2.  Bắt đầu quay màn hình (tập trung vào Dashboard Grafana).
3.  Tại terminal, chạy lệnh:
    ```bash
    make test-load
    ```
4.  Trên Grafana, quan sát và thuyết minh (nếu cần):
    - Khi đường **VUs** (User ảo) dựng đứng lên.
    - Chỉ ra rằng **RPS** tăng theo tương ứng.
    - Nhấn mạnh rằng **Latency** vẫn thấp và ổn định.
5.  Kết thúc quay khi test chạy xong.

### Kịch bản 3: Tìm Giới hạn (Stress Test)

_Mục đích: Tìm điểm gãy (Breaking Point) cho báo cáo._

1.  Tại terminal, chạy lệnh:
    ```bash
    make test-stress
    ```
2.  Quan sát kỹ Dashboard:
    - Ghi lại con số **RPS** cao nhất trước khi đường **Error** xuất hiện màu đỏ hoặc **Latency** vượt quá 2 giây.
    - Đây chính là con số "Max Capacity" của hệ thống trên môi trường này.

---

## Giai đoạn 3: Thu thập & Dọn dẹp (Cleanup)

1.  **Lưu bằng chứng**:

    - Chụp ảnh màn hình Dashboard Grafana ở các thời điểm quan trọng (đỉnh tải, lúc ổn định).
    - Lưu các ảnh vào thư mục `docs/images/load-test/`.

2.  **Dọn dẹp hệ thống**:
    Tắt toàn bộ container để giải phóng tài nguyên máy:
    ```bash
    make down
    ```

## Xử lý sự cố (Troubleshooting)

- **Lỗi "Login failed"**: Có thể do Database chưa kịp khởi động xong trước khi chạy test. Hãy đợi thêm 30s và thử lại.
- **Grafana không hiện dữ liệu**: Kiểm tra xem container `influxdb` và `prometheus` có đang chạy không (`docker ps`).
- **Máy bị treo**: Do Stress Test dùng quá nhiều tài nguyên. Hãy giảm số lượng target VUs trong file `tests/k6/stress-test.js`.
