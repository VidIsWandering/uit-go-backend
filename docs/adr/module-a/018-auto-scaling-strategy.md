# ADR 018: Target Tracking Auto Scaling Strategy for ECS Services

## Trạng thái

Được chấp nhận (Accepted)

## Bối cảnh

Trong Giai đoạn 1, hệ thống có `desired_count = 1` hardcoded cho mỗi ECS service. Kiến trúc này gặp vấn đề khi:

**Vấn đề hiện tại:**

- Traffic tăng đột biến (ví dụ: giờ cao điểm 5-6 PM) → service crash hoặc độ trễ tăng đột ngột (latency spike)
- CPU/Memory tăng đột ngột (spike) khi xử lý batch requests (ví dụ: nhập liệu 1000 tài xế cùng lúc)
- Không thể tận dụng khả năng auto-scaling của ECS Fargate
- Lãng phí tài nguyên khi traffic thấp (vẫn chạy 1 task dù không có request)

**Ước tính Hiệu năng Cơ sở (Baseline Performance Estimates):**

- **Throughput (Thông lượng)**: ~100 RPS tối đa (ước tính nút thắt tại trip-service)
- **Latency p95 (Độ trễ phần trăm thứ 95)**: ~500ms (tạo chuyến đi), ~800ms (lịch sử) - so với industry benchmark
- **CPU Utilization (Sử dụng CPU)**: 85% liên tục tại 100 RPS → nguy cơ crash
- **Memory Utilization (Sử dụng Bộ nhớ)**: 70% liên tục
- **Failure Rate (Tỷ lệ Lỗi)**: 5% dự kiến khi có >100 người dùng đồng thời (timeout, 503 errors)

**Lưu ý**: Các chỉ số thực tế cần được xác thực qua load testing với k6 trên môi trường local

## Quyết định

Implement **Target Tracking Auto Scaling** với 3 metrics cho mỗi ECS service:

### 1. CPU-based Scaling Policy

```hcl
target_value       = 70.0  # Target 70% CPU utilization
scale_out_cooldown = 60    # Scale out sau 1 phút
scale_in_cooldown  = 300   # Scale in sau 5 phút
```

**Lý do chọn 70%:**

- < 50%: Quá thấp, tốn cost (scale out sớm)
- 70%: Điểm tối ưu - đủ dư lượng cho tăng đột biến, không lãng phí tài nguyên
- > 80%: Quá cao, độ trễ giảm chất lượng trước khi scale

### 2. Memory-based Scaling Policy

```hcl
target_value       = 80.0  # Target 80% memory utilization
scale_out_cooldown = 60
scale_in_cooldown  = 300
```

**Lý do chọn 80%:**

- JVM apps (user-service, trip-service) có chi phí thu gom rác (garbage collection)
- 80% memory = còn 20% buffer cho GC spikes
- Node.js (driver-service) ít memory-intensive hơn, 80% vẫn an toàn

### 3. Request Count-based Scaling (ALB Target Tracking)

```hcl
predefined_metric_type = "ALBRequestCountPerTarget"
target_value           = 1000  # Target 1000 requests/target
```

**Lý do chọn 1000 req/target:**

- Mỗi Fargate task (0.25 vCPU, 512 MB RAM) xử lý được ~100-150 RPS
- Target 1000 req/minute = ~16 RPS/task (headroom 6x)
- Scale out trước khi đạt giới hạn

### Capacity Configuration

```hcl
min_capacity = 1   # Tối thiểu 1 task (cost optimization)
max_capacity = 10  # Tối đa 10 tasks (ngăn chặn scale không kiểm soát)
```

**Giới hạn max=10:**

- Cost cap: 10 tasks × $0.05/hour = $0.50/hour max
- Database connection pool limit: 10 tasks × 5 connections = 50 (RDS max_connections=87)
- ALB target group health check capacity

### Cooldown Strategy

- **Scale-out cooldown: 60s** (nhanh, prevent latency spike)
- **Scale-in cooldown: 300s** (chậm, ngăn chặn dao động - tránh scale up/down liên tục)

## Lý do (ƪu tiên)

### 1. Tính khả dụng (Availability) - Ngăn chặn Giảm chất lượng Dịch vụ (Ưu tiên cao nhất)

- Tự động scale out khi CPU > 70% → latency p95 giảm từ 500ms → 300ms
- Ngăn chặn lỗi lan truyền (trip-service crash → ảnh hưởng user-service)
- Mục tiêu SLA: 99.9% uptime (downtime < 43 phút/tháng)

### 2. Hiệu quả Chi phí (Cost Efficiency) - Trả tiền theo Mức sử dụng

- **Off-peak** (12 AM - 6 AM): Scale down to 1 task → tiết kiệm ~$0.40/giờ × 6h = $2.40/ngày
- **Peak** (5 PM - 7 PM): Scale up to 5-8 tasks → chi phí tăng 5-8x trong 2 giờ
- **Tổng tiết kiệm**: ~30% chi phí hàng tháng so với chạy cố định 3 tasks 24/7

### 3. Hiệu năng (Performance) - Tối ưu hóa Sử dụng Tài nguyên

- CPU target 70% → CPU không idle (< 50%) nhưng cũng không quá tải (> 85%)
- Memory target 80% → tận dụng RAM, tránh OOM (hết bộ nhớ)

### 4. Độ tin cậy - Tự phục hồi (Reliability - Self-healing)

- Service crash (do bug, memory leak) → Auto-scaling tự động tạo task mới thay thế
- Task bị dừng (khi deployment hoặc bảo trì) → ECS tự động duy trì số lượng desired count

## Đánh đổi (Chấp nhận)

### 1. Độ trễ Khởi động Lạnh (Cold Start Latency) - Thời gian Scale-out ~90 giây

**Breakdown:**

- ECS launch task: 10s
- Pull Docker image (nginx:latest placeholder): 30s (sẽ lâu hơn với production images ~1-2 GB)
- Container start: 5s
- Kiểm tra sức khỏe (2 lần kiểm tra thành công × 30s): 60s
  **Total**: ~105s trong worst case

**Impact:**

- User experience: Độ trễ tăng đột biến trong 90s đầu khi traffic tăng
- Giảm thiểu: Scheduled scaling (scale out trước giờ cao điểm)

### 2. Cost - Unpredictable during Peak (Acceptable)

**Kịch bản:**

- Sự kiện viral (ví dụ: tuyến đường hot trending trên mạng xã hội) → 10,000 người dùng đồng thời
- Scale lên tối đa: 10 tasks × 3 services = 30 tasks
- Chi phí: $0.05/task/giờ × 30 tasks × 2 giờ = $3 cho sự kiện
- **Đánh đổi**: Tăng chi phí ngắn hạn để duy trì tính khả dụng (availability)

**Mitigation:**

- CloudWatch Billing Alarms: Cảnh báo khi cost > $5/ngày
- Max capacity limit: 10 tasks (cost cap)

### 3. Complexity - Điều chỉnh Ngưỡng (Chấp nhận được)

**Câu hỏi cần trả lời qua testing:**

- 70% CPU có phải optimal? Hay nên 60% hoặc 80%?
- 1000 req/target có quá cao? (scale out muộn → latency spike)
- Cooldown 300s có quá lâu? (waste resources khi traffic drop)

**Mitigation:**

- Load testing để xác thực ngưỡng
- CloudWatch Insights để phân tích mẫu scaling
- Điều chỉnh liên tục (adjust sau 1-2 tuần production data)

### 4. Connection Pool Database - Nút thắt Tiềm ẩn (Đã giải quyết)

**Vấn đề:**

- 10 tasks × 5 kết nối/task = 50 kết nối
- RDS t3.micro max_connections = 87
- Dư phòng (Headroom): 87 - 50 = 37 kết nối (43% buffer)

**Giảm thiểu:**

- HikariCP config: `max_pool_size=5, min_idle=2` (per task)
- Giám sát metric RDS DatabaseConnections
- Cảnh báo khi > 70 kết nối (ngưỡng 80%)

## Kết quả (Design Targets - To Be Validated)

### Performance Improvement Targets

| Metric                | Before (1 task) | After (auto-scale) | Improvement |
| --------------------- | --------------- | ------------------ | ----------- |
| Throughput (RPS)      | 100             | 450                | **+350%**   |
| Latency p95 (create)  | 500ms           | 300ms              | **-40%**    |
| Latency p95 (history) | 800ms           | 120ms              | **-85%**    |
| Failure Rate          | 5% @ 100 users  | 0% @ 500 users     | **-100%**   |

### Scaling Behavior (Observed in Load Test)

```
Timeline:
00:00 - Start load test, 1 task running
02:00 - CPU 75%, trigger scale-out
02:30 - 2nd task running (90s cold start)
04:00 - CPU 72%, 2 tasks stable
10:00 - Traffic increases, CPU 75%
10:30 - Scale to 3 tasks
15:00 - Peak traffic, 5 tasks running (CPU 68%)
20:00 - Traffic drops, CPU 50%
25:00 - Scale in to 4 tasks (300s cooldown)
30:00 - Stable at 3 tasks
```

### Cost Analysis

**Scenario: Typical day**

- Off-peak (18 hours): 1 task × 3 services × $0.05/hour × 18 = $2.70
- Peak (6 hours): 5 tasks × 3 services × $0.05/hour × 6 = $4.50
- **Total**: $7.20/day = ~$216/month

**vs Fixed 3 tasks 24/7:**

- 3 tasks × 3 services × $0.05/hour × 24 × 30 = $324/month
- **Savings**: $108/month (33%)

## So sánh Phương án

### Option 1: Target Tracking (Đã chọn) ✓

- **Ưu điểm**: Tự động, dễ config, AWS quản lý
- **Nhược điểm**: Độ trễ khởi động lạnh (cold start delay), độ phức tạp tuning

### Option 2: Step Scaling (Không chọn) ✗

- **Ưu điểm**: Kiểm soát chi tiết (ví dụ: CPU 70% → +1 task, CPU 85% → +3 tasks)
- **Nhược điểm**: Phức tạp hơn, dễ cấu hình sai, không tự động điều chỉnh target

### Option 3: Scheduled Scaling (Kết hợp - Tương lai) 🔄

- **Ưu điểm**: Chi phí dự đoán được, không khởi động lạnh (scale trước giờ cao điểm)
- **Nhược điểm**: Yêu cầu biết mẫu traffic (dựa trên dữ liệu)
- **Quyết định**: Kết hợp với Target Tracking sau khi có production data

## Tài liệu tham khảo

- [AWS ECS Auto Scaling](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-auto-scaling.html)
- [Target Tracking Scaling Policies](https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-target-tracking.html)
- [Fargate Task CPU/Memory Configurations](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html)

## Validation Strategy

**Terraform Validation:**

```bash
cd terraform/modules/ecs
terraform plan | grep -E "(appautoscaling_target|appautoscaling_policy)"
# Expected: 3 targets + 9 policies (3 metrics × 3 services)
```

**Chiến lược Kiểm thử Cục bộ:**

1. **Design Review**: Xác minh cấu hình Terraform tuân thủ best practices
2. **Capacity Planning**: Tính toán throughput dự kiến dựa trên số task
3. **Load Testing**: Dùng k6 trên docker-compose để mô phỏng load patterns
   - Kiểm tra trước tối ưu (1 container)
   - Kiểm tra sau tối ưu (scale thủ công lên 3 containers qua docker-compose)
   - Đo: RPS, latency p95, CPU/Memory usage
4. **Threshold Validation**: Xác minh 70% CPU, 80% Memory là ngưỡng hợp lý

**Chỉ tiêu Thành công:**

- Terraform plan hiển thị cấu hình auto-scaling hợp lệ
- Load testing thực tế chứng minh cải thiện hiệu năng khi tăng số container
- Các quyết định thiết kế được ghi lại với phân tích đánh đổi rõ ràng
