# Kế hoạch Chi tiết Module A: Scalability & Performance

## Thông tin chung

- **Module**: Module A - Thiết kế Kiến trúc cho Scalability & Performance
- **Thời gian**: Tuần 9-12 (4 tuần)
- **Mục tiêu**: Thiết kế kiến trúc hyper-scale, kiểm chứng bằng load testing, và hiện thực hóa các kỹ thuật tối ưu

---

## Tổng quan 3 Nhiệm vụ chính (theo tài liệu SE360)

### 1. Phân tích và Bảo vệ Lựa chọn Kiến trúc (20% điểm Module)

**Mục tiêu**: Phân tích bottleneck hiện tại, đề xuất và bảo vệ các quyết định thiết kế mới.

**Deliverables**:

- ADRs mới cho các quyết định Module A
- So sánh kiến trúc đồng bộ (REST) vs bất đồng bộ (SQS)
- Phân tích trade-offs: Latency vs Throughput, Cost vs Performance

### 2. Kiểm chứng Thiết kế bằng Load Testing (Implicit)

**Mục tiêu**: Xây dựng kịch bản load testing, tìm bottleneck, đo giới hạn hệ thống.

**Deliverables**:

- Scripts load testing (k6)
- Báo cáo kết quả: request/giây, latency p95/p99, CPU/Memory
- Biểu đồ trước và sau tối ưu

### 3. Hiện thực hóa các Kỹ thuật Tối ưu (20% điểm Module)

**Mục tiêu**: Áp dụng caching, auto scaling, read replicas.

**Deliverables**:

- Spring Cache + Redis implementation
- Terraform Auto Scaling policies
- RDS Read Replica setup
- Resilience4j Circuit Breaker

---

## Phân công Công việc (2 thành viên)

### **Role A - Nguyễn Việt Khoa (Backend Developer)**

**Trách nhiệm**: Code-level optimization (Java services) + Load Testing

#### Tasks của Role A:

**Week 9-10: Optimization Implementation (Java)**

- [ ] **Task A.1**: Implement Spring Cache cho TripService

  - Cache trip history (passenger/driver)
  - Cache driver search results (TTL: 30s)
  - Cache invalidation strategy
  - File: `TripService.java`, config: `application.properties`

- [ ] **Task A.2**: Thêm Resilience4j Circuit Breaker

  - Circuit Breaker cho DriverService calls
  - Retry policy + Timeout
  - Fallback mechanism
  - File: `DriverService.java`, `pom.xml`

- [ ] **Task A.3**: Tối ưu HikariCP Connection Pool

  - Tính toán pool size hợp lý
  - Config cho user-service và trip-service
  - Monitor connection usage
  - File: `application.properties` (cả 2 services)

- [ ] **Task A.4**: Tối ưu RestTemplate HTTP Client
  - Thêm Apache HttpClient với connection pooling
  - Config timeout hợp lý
  - File: `RestTemplateConfig.java`

**Week 11: Load Testing Setup & Execution**

- [ ] **Task A.5**: Viết k6 Load Testing Scripts

  - Script 1: User registration + login (baseline)
  - Script 2: Create trip flow (find driver + create trip)
  - Script 3: Driver location update (write-heavy)
  - Script 4: Trip history query (read-heavy)
  - Folder: `load-testing/scripts/`

- [ ] **Task A.6**: Thực thi Load Tests (Before Optimization)
  - Chạy tests trên local hoặc staging
  - Ghi nhận metrics: RPS, latency p95/p99, error rate
  - Screenshot Grafana dashboards
  - File: `load-testing/results/before-optimization.md`

**Week 12: Re-test & Report**

- [ ] **Task A.7**: Thực thi Load Tests (After Optimization)

  - Chạy lại tests sau khi Role B deploy auto-scaling
  - So sánh kết quả before/after
  - File: `load-testing/results/after-optimization.md`

- [ ] **Task A.8**: Viết ADR cho Code Optimization

  - ADR-013: Spring Cache Strategy
  - ADR-014: Circuit Breaker Pattern
  - ADR-015: Connection Pool Sizing
  - Folder: `docs/adr/`

- [ ] **Task A.9**: Chuẩn bị Demo + Presentation
  - Demo load testing live
  - Trình bày biểu đồ so sánh

---

### **Role B - Nguyễn Quốc Bảo (Platform Engineer)**

**Trách nhiệm**: Infrastructure optimization (Terraform) + Architecture design

#### Tasks của Role B:

**Week 9-10: Infrastructure Optimization (Terraform)**

- [ ] **Task B.1**: Tách Security Groups theo Service

  - Tạo 3 SGs riêng: user-service-sg, trip-service-sg, driver-service-sg
  - Tạo 2 DB SGs: user-db-sg, trip-db-sg (chỉ cho phép từ service tương ứng)
  - Update ECS services để dùng SG riêng
  - File: `terraform/modules/database/main.tf`, `terraform/modules/ecs/main.tf`

- [ ] **Task B.2**: Thêm Auto Scaling cho ECS Services

  - Target Tracking Scaling (CPU 70%)
  - Target Tracking Scaling (Memory 80%)
  - Min: 1, Max: 10 tasks
  - File: `terraform/modules/ecs/main.tf` (thêm `aws_appautoscaling_target`, `aws_appautoscaling_policy`)

- [ ] **Task B.3**: Thêm RDS Read Replica cho trip_db

  - Tạo read replica trong cùng region (hoặc multi-AZ)
  - Update connection string cho read-only queries
  - File: `terraform/modules/database/main.tf`

- [ ] **Task B.4**: Thêm Redis Backup & Persistence
  - Config snapshot retention (5 days)
  - Config snapshot window
  - File: `terraform/modules/database/main.tf`

**Week 11: Architecture Analysis & Documentation**

- [ ] **Task B.5**: Nghiên cứu Async Architecture (SQS)

  - Thiết kế luồng: TripService → SQS → DriverService
  - Vẽ sơ đồ kiến trúc mới (Draw.io)
  - Phân tích trade-offs: Latency vs Decoupling
  - File: `docs/diagrams/async_architecture_module_a.drawio`

- [ ] **Task B.6**: Viết ADR cho Infrastructure Decisions

  - ADR-016: Security Group Segregation
  - ADR-017: Auto Scaling Strategy
  - ADR-018: RDS Read Replica vs Caching
  - ADR-019: Async Communication (SQS) - Design Only
  - Folder: `docs/adr/`

- [ ] **Task B.7**: Cập nhật ARCHITECTURE.md
  - Thêm phần "Module A Enhancements"
  - Sơ đồ kiến trúc mới (có auto-scaling, read replica)
  - File: `docs/ARCHITECTURE.md`

**Week 12: Deployment & Final Integration**

- [ ] **Task B.8**: Deploy Infrastructure Changes

  - `terraform apply` cho tất cả thay đổi
  - Verify auto-scaling hoạt động
  - Monitor CloudWatch metrics

- [ ] **Task B.9**: Setup CloudWatch Alarms

  - Alarm cho CPU > 80% (trigger scaling)
  - Alarm cho ECS task failures
  - Alarm cho RDS connection pool saturation
  - File: `terraform/modules/ecs/cloudwatch.tf` (new file)

- [ ] **Task B.10**: Hoàn thiện REPORT.md (Module A Section)
  - Section 2: Phân tích Module chuyên sâu
  - Section 3: Trade-offs summary
  - File: `docs/REPORT.md`

---

## Dependencies & Integration Points

### ⚠️ AWS Strategy Update

**Current Plan**: Development & testing on **Local Docker Compose**

- Reason: AWS Free Tier constraints (ALB limit, cost concerns)
- Approach: Terraform code validated with `terraform plan` (not deployed)
- Load testing: Local environment (valid for relative improvements)
- Cost: $0

**Future Option**: Deploy to AWS if instructor requires (1 day, ~$5-8 cost)

### Critical Path (phải làm theo thứ tự):

1. **Week 9**: Role B làm Task B.1-B.4 (Terraform code) → Role A test local
2. **Week 10**: Role A làm Task A.1-A.4 (optimizations) → commit code
3. **Week 11**: Role A làm Task A.5-A.6 (load testing BEFORE on local)
4. **Week 11**: Role B validate Terraform (Task B.8 - plan only, not deploy)
5. **Week 12**: Role A làm Task A.7 (load testing AFTER on local)
6. **Week 12**: (Optional) Deploy to AWS for 1 day if instructor requires

### Integration Points (cần sync):

- **Sync 1 (End of Week 9)**: Role B xác nhận Terraform code ready → Role A continue local testing
- **Sync 2 (End of Week 10)**: Role A push code với caching → Role B review config
- **Sync 3 (Mid Week 11)**: Role A share load test kết quả "before" (local) → Role B verify bottleneck
- **Sync 4 (End Week 11)**: Role B xác nhận Terraform validated → Role A chạy load test "after" (local)
- **Sync 5 (Week 12)**: Merge tất cả ADRs, finalize REPORT.md
- **Sync 6 (Week 12 - Optional)**: If instructor requires AWS → coordinate 1-day deployment

---

## Deliverables Checklist (Cuối Module A)

### Code & Configuration

- [ ] Spring Cache implementation (Role A)
- [ ] Circuit Breaker implementation (Role A)
- [ ] Connection pool tuning (Role A)
- [ ] Terraform auto-scaling (Role B)
- [ ] Terraform SG segregation (Role B)
- [ ] Terraform RDS read replica (Role B)

### Load Testing

- [ ] k6 scripts (4 scenarios) (Role A)
- [ ] Before optimization results (Role A)
- [ ] After optimization results (Role A)
- [ ] Grafana screenshots (Role A)

### Documentation

- [ ] 4 ADRs từ Role A (013-016)
- [ ] 4 ADRs từ Role B (017-020)
- [ ] Updated ARCHITECTURE.md (Role B)
- [ ] Updated REPORT.md Section 2-3 (Role B lead, Role A contribute)
- [ ] Async architecture diagram (Role B)

### Presentation

- [ ] Demo slides (Both)
- [ ] Load testing live demo script (Role A)
- [ ] Architecture evolution explanation (Role B)

---

## Expected Outcomes (Metrics)

### Performance Improvements (Target)

- **Throughput**: 100 RPS → 500+ RPS (5x improvement)
- **Latency p95**: < 200ms cho trip search
- **Cache Hit Rate**: > 80% cho trip history queries
- **Auto-scaling**: Scale from 1→5 tasks trong 2 phút khi CPU > 70%

### Cost Analysis

- Auto-scaling giảm 30% cost khi low traffic (scale to min)
- Read replica tăng ~50% RDS cost nhưng giảm 70% load trên primary

---

## Risk Mitigation

### Risks & Mitigations:

1. **Risk**: Auto-scaling không hoạt động đúng

   - **Mitigation**: Test scaling bằng stress test trước Week 12

2. **Risk**: Load testing gây crash services

   - **Mitigation**: Chạy trên staging/local trước, tăng dần load

3. **Risk**: Spring Cache invalidation không đúng

   - **Mitigation**: Viết integration test cho cache logic

4. **Risk**: Role A & B conflict khi merge code
   - **Mitigation**: Commit thường xuyên, review code qua PR

---

## Notes for Independent Work

### Role A (Khoa) - You can work independently on:

- Tất cả Java code changes (không cần Terraform)
- Load testing scripts (chạy được trên local Docker Compose)
- ADRs của bạn (013-016)
- Chỉ cần **wait** Role B deploy infrastructure (Week 11) để chạy final load test

### Role B (Bảo) - You can work independently on:

- Tất cả Terraform changes (không ảnh hưởng code)
- Architecture diagrams & ADRs (017-020)
- CloudWatch setup
- Chỉ cần **wait** Role A finish caching code (Week 10) để deploy lên AWS

### Communication Protocol:

- **Daily standup** (async via chat): "Hôm nay tôi làm task X, block: Y/N"
- **Weekly sync** (15 phút): Review integration points
- **Shared Google Doc**: Track progress real-time

---

## Appendix: Folder Structure (After Module A)

```
uit-go-backend/
├── docs/
│   ├── adr/
│   │   ├── 013-spring-cache-strategy.md          # Role A
│   │   ├── 014-circuit-breaker-pattern.md        # Role A
│   │   ├── 015-connection-pool-sizing.md         # Role A
│   │   ├── 016-http-client-pooling.md            # Role A
│   │   ├── 017-security-group-segregation.md     # Role B
│   │   ├── 018-auto-scaling-strategy.md          # Role B
│   │   ├── 019-rds-read-replica.md               # Role B
│   │   └── 020-async-sqs-design.md               # Role B
│   ├── diagrams/
│   │   └── async_architecture_module_a.drawio    # Role B
│   ├── ARCHITECTURE.md                           # Updated by Role B
│   └── REPORT.md                                 # Updated by both
├── load-testing/
│   ├── scripts/
│   │   ├── scenario-1-baseline.js                # Role A
│   │   ├── scenario-2-create-trip.js             # Role A
│   │   ├── scenario-3-driver-updates.js          # Role A
│   │   └── scenario-4-trip-history.js            # Role A
│   └── results/
│       ├── before-optimization.md                # Role A
│       └── after-optimization.md                 # Role A
├── terraform/
│   └── modules/
│       ├── database/
│       │   └── main.tf                           # Updated by Role B
│       └── ecs/
│           ├── main.tf                           # Updated by Role B
│           └── cloudwatch.tf                     # New by Role B
├── user-service/
│   └── src/.../
│       └── application.properties                # Updated by Role A
└── trip-service/
    └── src/.../
        ├── TripService.java                      # Updated by Role A
        ├── DriverService.java                    # Updated by Role A
        ├── RestTemplateConfig.java               # Updated by Role A
        ├── application.properties                # Updated by Role A
        └── pom.xml                               # Updated by Role A (add dependencies)
```

---

**END OF MODULE_A_PLAN.md**
