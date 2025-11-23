# ADR 004: Chiến lược Tự động Mở rộng (Auto-scaling Strategy)

## Bối cảnh

Lưu lượng người dùng gọi xe thay đổi mạnh theo khung giờ (giờ cao điểm sáng/chiều, ngày lễ). Việc duy trì số lượng server cố định là lãng phí (khi thấp điểm) hoặc thiếu hụt (khi cao điểm).

## Quyết định

Áp dụng **Auto-scaling** đa tầng.

1.  **Compute Scaling (AWS ECS Service Auto Scaling)**:

    - Metric: CPU Utilization & Memory Utilization.
    - Policy: Target Tracking Scaling (Giữ CPU ở mức 70%).
    - Scale Out: Thêm task khi CPU > 70% trong 3 phút.
    - Scale In: Giảm task khi CPU < 30% trong 15 phút.

2.  **Database Scaling (AWS RDS Storage Auto Scaling)**:
    - **Storage**: Tự động tăng dung lượng ổ cứng khi sắp đầy (Storage Auto Scaling).
    - **Compute (CPU/RAM)**:
      - Trong phạm vi đồ án, chúng ta tập trung vào **Read Scalability** thông qua Read Replicas (ADR-002) vì đây là điểm nghẽn phổ biến nhất của ứng dụng đọc nhiều.
      - Đối với Write Scalability (Vertical Scaling), giải pháp lý tưởng cho Hyper-scale là sử dụng **Amazon Aurora Serverless v2** (tự động scale ACU theo tải). Tuy nhiên, để tiết kiệm chi phí cho môi trường sinh viên, chúng ta sẽ giữ nguyên instance class (ví dụ: db.t3.micro) và chỉ scale Storage + Read Replicas. Thiết kế này vẫn đảm bảo tính "Cloud-Native" và sẵn sàng nâng cấp lên Aurora khi cần thiết.

## Hệ quả

### Tích cực

- **Cost Optimization**: Chỉ trả tiền cho tài nguyên thực sự sử dụng.
- **Reliability**: Hệ thống tự động "phình to" để chịu tải khi có sự kiện bất ngờ.

### Tiêu cực

- **Cold Start**: Thời gian khởi động container mới có thể mất 1-2 phút. Cần cấu hình `Min Capacity` hợp lý để luôn có sẵn server.
- **Flapping**: Nếu ngưỡng scale out/in quá gần nhau, hệ thống sẽ scale liên tục gây bất ổn.

## Trạng thái

Accepted
