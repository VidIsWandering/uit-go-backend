# Báo cáo Tổng kết Dự án UIT-Go Backend

## 1. Tổng quan kiến trúc hệ thống

![Sơ đồ Kiến trúc AWS](images/architecture/aws-cloud-architecture.png)

Hệ thống UIT-Go Backend được xây dựng theo mô hình microservices, triển khai trên AWS với các thành phần chính:

- **ECS Fargate Cluster**: Chạy các service User, Trip, Driver.
- **RDS PostgreSQL (Primary & Read Replica)**: Lưu trữ dữ liệu giao dịch và phân tải đọc.
- **ElastiCache Redis**: Caching và xử lý dữ liệu vị trí.
- **Amazon SQS**: Hàng đợi bất đồng bộ cho luồng đặt chuyến.
- **ALB, NAT Gateway, Secrets Manager, CloudWatch, ECR**: Đảm bảo bảo mật, vận hành và quản lý hiện đại.

> Xem chi tiết tại: [ARCHITECTURE.md](ARCHITECTURE.md)

---

## 2. Phân tích Module chuyên sâu: Scalability & Performance (Module A)

### Cách tiếp cận

- **Async Processing**: Tách luồng đặt chuyến thành producer (Trip Service) và consumer (Driver Service) qua SQS.
- **Read Replicas**: Tối ưu hóa truy vấn đọc với RDS Read Replica, giảm tải cho Primary.
- **Centralized Caching**: Sử dụng Redis cho các truy vấn vị trí và profile có tần suất cao.
- **Auto Scaling**: Cấu hình scaling động cho ECS và RDS dựa trên CPU, Memory, Request Count.
- **Concurrency Control**: Áp dụng Optimistic Locking cho các thao tác nhận chuyến.

### Kết quả tuning & load test 2

#### Discovery quan trọng: JVM Warmup Strategy

**Phát hiện**: Hệ thống cần 5 phút warmup để JIT compiler tối ưu bytecode → Cải thiện 60% performance.

- **Warmup Test**: 50 VUs sustained trong 5 phút
  - **p(95) Latency**: 58ms (excellent baseline)
  - **Throughput**: 83 req/s
  - **Error Rate**: 0%
  - **Impact**: Không warmup → Spike test FAIL; Có warmup → PASS ✅

#### So sánh Baseline vs Tuning

| Metric              | Load Test 1 (Baseline)  | Load Test 2 (Tuning)    | Cải thiện        |
| ------------------- | ----------------------- | ----------------------- | ---------------- |
| **Spike - p95**     | 1.94s (100 VUs)         | 3.38s (300 VUs)         | 3x tải, +74% latency |
| **Spike - RPS**     | ~29 req/s               | ~103 req/s              | **+255%** ⬆️     |
| **Spike - Errors**  | 0.00%                   | 0.00%                   | Maintained       |
| **Stress - p95**    | 6.78s (500 VUs)         | 5.03s (500 VUs)         | **-25.8%** ⬇️    |
| **Stress - RPS**    | ~56 req/s (bão hòa)     | ~98 req/s               | **+75%** ⬆️      |
| **Stress - Errors** | 0.04% (5 connection reset) | 0.00%                   | **-100%** ⬇️     |
| **Capacity Limit**  | Degrade nghiêm trọng >300 VUs | Stable tới 500 VUs      | **+67% capacity** |

#### Kết quả chi tiết từng test

**Spike Test (300 VUs - 50 seconds)**
- **Objective**: Kiểm tra khả năng xử lý tải đột ngột cao gấp 3 lần baseline
- **p(95) Latency**: 3,376ms < 3,700ms threshold ✅ **PASSED**
- **Total Iterations**: 5,137 requests
- **Throughput**: ~103 req/s (tăng 255% so với baseline)
- **Error Rate**: 0% (zero HTTP errors)
- **Kết luận**: Hệ thống scale tốt với tải cao, SQS queue hấp thụ burst traffic hiệu quả.

**Stress Test (500 VUs - 5.5 minutes)**
- **Objective**: Tìm giới hạn chịu tải của hệ thống sau tuning
- **p(95) Latency**: 5,033ms < 6,500ms threshold ✅ **PASSED**
- **Total Iterations**: 32,372 requests
- **Throughput**: ~98 req/s (tăng 75% so với baseline)
- **Error Rate**: 0% (giảm từ 0.04% → 0%, loại bỏ hoàn toàn connection reset)
- **Kết luận**: Connection pool tuning + Read Replica loại bỏ bottleneck, hệ thống stable ở 500 VUs.

#### Hiệu quả từng giải pháp

**1. Async Processing (SQS)**
- **Spike Test Impact**: Hấp thụ 300 VUs burst traffic, 0% error rate
- **Queue Performance**: Decouple Trip Service → Driver Service thành công
- **Trade-off**: Thêm latency ~50-100ms nhưng tăng throughput 255%

**2. Read Replicas**
- **Stress Test Impact**: Giảm 25.8% p95 latency (6.78s → 5.03s)
- **Connection Pool**: Loại bỏ pending connections, không còn timeout
- **Capacity Increase**: Từ 300 VUs → 500 VUs (+67% capacity)

**3. JVM Warmup**
- **Critical Discovery**: Mandatory cho production deployment
- **Performance Gain**: 60% improvement sau warmup
- **Implementation**: 5-minute warmup script trước mỗi test/deployment

**4. Load Balancing (3 Trip Service Replicas)**
- **Throughput**: Phân tải đều, RPS tăng từ 56 → 98 req/s
- **Availability**: 0% downtime, nginx reverse proxy routing hiệu quả

#### Kết luận Module A

✅ **Thành công vượt trội**:
- Tăng 255% throughput ở spike test (29 → 103 req/s)
- Tăng 75% throughput ở stress test (56 → 98 req/s)
- Giảm 25.8% latency p95 ở stress test (6.78s → 5.03s)
- Loại bỏ hoàn toàn errors (0.04% → 0%)
- Tăng 67% capacity (300 → 500 VUs stable)

⚠️ **Trade-offs chấp nhận được**:
- Spike latency tăng 74% (1.94s → 3.38s) nhưng vẫn PASS threshold và tải tăng 3x
- Complexity tăng (SQS, Read Replica, Warmup strategy)
- Chi phí AWS tăng (multi-AZ RDS, ElastiCache, SQS)

🎯 **Đạt mục tiêu Hyper-scale**: Hệ thống sẵn sàng production với khả năng xử lý 500+ concurrent users.

---

## 3. Tổng hợp các quyết định thiết kế & Trade-off (Quan trọng nhất)

| ADR         | Quyết định chính                                           | Lý do ưu tiên                     | Đánh đổi/Trade-off        |
| ----------- | ---------------------------------------------------------- | --------------------------------- | ------------------------- |
| ADR-001     | RESTful API                                                | Đơn giản, đa ngôn ngữ             | Overhead HTTP/JSON        |
| ADR-002     | Redis Geospatial                                           | Truy vấn vị trí cực nhanh         | Tốn RAM, chi phí Redis    |
| ADR-003     | Polyglot                                                   | Đúng tool cho đúng việc           | Phức tạp vận hành         |
| ADR-004     | Polling                                                    | Dễ triển khai                     | Độ trễ cập nhật           |
| ADR-005     | Terraform (IaC)                                            | Quản lý hạ tầng chuẩn             | Học cú pháp, debug khó    |
| ADR-006/007 | Secrets/Private Subnet                                     | Bảo mật tối đa                    | Debug phức tạp            |
| ADR-008/009 | ECS Fargate                                                | Không quản lý server              | Chi phí cao hơn EC2       |
| ADR-010     | Modular Terraform                                          | Dễ bảo trì, mở rộng               | Refactor tốn công         |
| ADR-011     | Cloud Map                                                  | Service Discovery nội bộ          | Tăng cấu hình             |
| ADR-012     | ECR                                                        | Registry bảo mật                  | Vendor lock-in            |
| ADR-013     | SG Segregation                                             | Least Privilege, Defense in Depth | Quản lý rules phức tạp    |
| Module A    | SQS, Read Replica, Redis, Auto Scaling, Optimistic Locking | Đạt hyper-scale                   | Tăng chi phí, độ phức tạp |

---

## 4. Thách thức & Bài học kinh nghiệm

### Thách thức

- **Giới hạn AWS**: Quota thấp, phải xin tăng hạn mức.
- **Quản lý IaC**: Refactor Terraform modules, debug resource dependencies.
- **Đồng bộ đa ngôn ngữ**: Mapping DTOs giữa Java và Node.js.
- **Tối ưu hiệu năng**: Phát hiện và xử lý bottleneck DB, tuning connection pool.

### Bài học kinh nghiệm

- **ADR giúp minh bạch hóa quyết định và tránh tranh luận lặp lại.**
- **IaC là chìa khóa cho vận hành hiện đại, nhưng cần đầu tư thời gian học và refactor.**
- **Kiến trúc tốt phải luôn cân bằng giữa hiệu năng, chi phí và độ phức tạp.**

---

## 5. Kết quả & Hướng phát triển

### Kết quả đã đạt được

- Hoàn thiện kiến trúc cloud-native, IaC 100%.
- Đáp ứng đầy đủ các user stories và yêu cầu phi chức năng.
- Đã thực hiện load test 1 (baseline), xác định bottleneck và lên kế hoạch tuning.

### Hướng phát triển tiếp theo

- **Cập nhật kết quả tuning & load test 2** (bổ sung sau).
- Triển khai CI/CD tự động hóa.
- Mở rộng sang các module Reliability, Security, Cost Optimization.
- Đề xuất tích hợp thêm các giải pháp observability (tracing, alerting).
