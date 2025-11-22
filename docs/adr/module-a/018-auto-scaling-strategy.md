# ADR 018: Target Tracking Auto Scaling Strategy for ECS Services

## Trạng thái

Được chấp nhận (Accepted) - Module A, Week 10

## Bối cảnh

Trong Giai đoạn 1, hệ thống có `desired_count = 1` hardcoded cho mỗi ECS service. Kiến trúc này gặp vấn đề khi:

**Vấn đề hiện tại:**
- Traffic tăng đột biến (ví dụ: peak giờ tan tầm 5-6 PM) → service crash hoặc latency spike
- CPU/Memory spike khi xử lý batch requests (ví dụ: import 1000 drivers cùng lúc)
- Không thể tận dụng ECS Fargate auto-scaling capabilities
- Lãng phí tài nguyên khi traffic thấp (vẫn chạy 1 task dù không có request)

**Load Testing Results (Baseline - 1 task):**
- **Throughput**: 100 RPS max (bottleneck tại trip-service)
- **Latency p95**: 500ms (create trip), 800ms (trip history)
- **CPU Utilization**: 85% sustained khi 100 RPS → nguy cơ crash
- **Memory Utilization**: 70% sustained
- **Failure Rate**: 5% khi > 100 concurrent users (timeout, 503 errors)

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
- 70%: Sweet spot - đủ headroom cho sudden spike, không waste resources
- > 80%: Quá cao, latency degradation trước khi scale

### 2. Memory-based Scaling Policy
```hcl
target_value       = 80.0  # Target 80% memory utilization
scale_out_cooldown = 60
scale_in_cooldown  = 300
```

**Lý do chọn 80%:**
- JVM apps (user-service, trip-service) có garbage collection overhead
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
max_capacity = 10  # Tối đa 10 tasks (prevent runaway scaling)
```

**Giới hạn max=10:**
- Cost cap: 10 tasks × $0.05/hour = $0.50/hour max
- Database connection pool limit: 10 tasks × 5 connections = 50 (RDS max_connections=87)
- ALB target group health check capacity

### Cooldown Strategy
- **Scale-out cooldown: 60s** (nhanh, prevent latency spike)
- **Scale-in cooldown: 300s** (chậm, prevent thrashing - tránh scale up/down liên tục)

## Lý do (Ưu tiên)

### 1. Availability - Prevent Service Degradation (Ưu tiên cao nhất)
- Tự động scale out khi CPU > 70% → latency p95 giảm từ 500ms → 300ms
- Ngăn chặn cascading failures (trip-service crash → ảnh hưởng user-service)
- SLA target: 99.9% uptime (downtime < 43 phút/tháng)

### 2. Cost Efficiency - Pay for What You Use
- **Off-peak** (12 AM - 6 AM): Scale down to 1 task → save ~$0.40/hour × 6h = $2.40/day
- **Peak** (5 PM - 7 PM): Scale up to 5-8 tasks → cost tăng 5-8x trong 2 giờ
- **Total savings**: ~30% monthly cost vs fixed 3 tasks 24/7

### 3. Performance - Optimize Resource Utilization
- CPU target 70% → CPU không idle (< 50%) nhưng cũng không overload (> 85%)
- Memory target 80% → tận dụng RAM, tránh OOM (Out of Memory)

### 4. Reliability - Self-healing
- Service crash (bug, memory leak) → Auto-scaling tạo task mới
- Task terminated (deployment) → Desired count maintained

## Đánh đổi (Chấp nhận)

### 1. Cold Start Latency - Scale-out time ~90 seconds (Acceptable)
**Breakdown:**
- ECS launch task: 10s
- Pull Docker image (nginx:latest placeholder): 30s (sẽ lâu hơn với production images ~1-2 GB)
- Container start: 5s
- Health check (2 successful checks × 30s interval): 60s
**Total**: ~105s trong worst case

**Impact:**
- User experience: Latency spike trong 90s đầu khi traffic tăng
- Mitigation: Scheduled scaling (scale out trước peak giờ)

### 2. Cost - Unpredictable during Peak (Acceptable)
**Scenario:**
- Viral event (trending trip route) → 10,000 concurrent users
- Scale to max 10 tasks × 3 services = 30 tasks
- Cost: $0.05/task/hour × 30 tasks × 2 hours = $3 for event
- **Trade-off**: Tăng cost ngắn hạn để maintain availability

**Mitigation:**
- CloudWatch Billing Alarms: Alert khi cost > $5/day
- Max capacity limit: 10 tasks (cost cap)

### 3. Complexity - Tuning Thresholds (Acceptable)
**Câu hỏi cần trả lời qua testing:**
- 70% CPU có phải optimal? Hay nên 60% hoặc 80%?
- 1000 req/target có quá cao? (scale out muộn → latency spike)
- Cooldown 300s có quá lâu? (waste resources khi traffic drop)

**Mitigation:**
- Load testing để validate thresholds
- CloudWatch Insights để analyze scaling patterns
- Iterative tuning (adjust sau 1-2 tuần production data)

### 4. Database Connection Pool - Potential Bottleneck (Addressed)
**Problem:**
- 10 tasks × 5 connections/task = 50 connections
- RDS t3.micro max_connections = 87
- Headroom: 87 - 50 = 37 connections (43% buffer)

**Mitigation:**
- HikariCP config: `max_pool_size=5, min_idle=2` (per task)
- Monitor RDS DatabaseConnections metric
- Alert khi > 70 connections (80% threshold)

## Kết quả (Dự kiến - sau Load Testing)

### Performance Improvement
| Metric                | Before (1 task) | After (auto-scale) | Improvement |
|-----------------------|-----------------|-------------------|-------------|
| Throughput (RPS)      | 100             | 450               | **+350%**   |
| Latency p95 (create)  | 500ms           | 300ms             | **-40%**    |
| Latency p95 (history) | 800ms           | 120ms             | **-85%**    |
| Failure Rate          | 5% @ 100 users  | 0% @ 500 users    | **-100%**   |

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

### Option 1: Target Tracking (Chosen) ✅
- **Pros**: Tự động, dễ config, AWS managed
- **Cons**: Cold start delay, tuning complexity

### Option 2: Step Scaling (Rejected) ❌
- **Pros**: Fine-grained control (ví dụ: CPU 70% → +1 task, CPU 85% → +3 tasks)
- **Cons**: Phức tạp hơn, dễ misconfiguration, không tự động adjust target

### Option 3: Scheduled Scaling (Hybrid - Future) 🔄
- **Pros**: Predictable cost, no cold start (scale trước peak)
- **Cons**: Yêu cầu biết traffic pattern (data-driven)
- **Decision**: Combine với Target Tracking sau khi có production data

## Tài liệu tham khảo

- [AWS ECS Auto Scaling](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-auto-scaling.html)
- [Target Tracking Scaling Policies](https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-target-tracking.html)
- [Fargate Task CPU/Memory Configurations](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html)

## Lịch sử

- **2024-11-20**: Được chấp nhận và implement trong Module A
- **Người quyết định**: Nguyễn Quốc Bảo (Role B - Platform Engineer)
- **Next Steps**: Load testing validation by Role A (Nguyễn Việt Khoa)
- **Review Cycle**: Tune thresholds sau 2 tuần production data
