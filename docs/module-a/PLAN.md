# Module A: Scalability & Performance - Kế hoạch Tổng quan

## 📋 Thông tin Cơ bản

- **Module**: Module A - Thiết kế Kiến trúc cho Scalability & Performance
- **Timeline**: Tuần 9-12 (4 tuần)
- **Team**: 2 thành viên (Role A: Backend, Role B: Platform)
- **Mục tiêu**: Phân tích, thiết kế và hiện thực hóa kiến trúc hyper-scale với kiểm chứng load testing

---

## 🎯 3 Nhiệm vụ Chính (theo SE360)

### 1. Phân tích và Bảo vệ Lựa chọn Kiến trúc (20% điểm)

**Deliverables**:

- 8 ADRs: Code optimizations (4) + Infrastructure (4)
- Trade-off analysis: Latency vs Throughput, Cost vs Performance
- Async architecture design (SQS)

### 2. Kiểm chứng bằng Load Testing

**Deliverables**:

- 4 k6 load testing scenarios
- Before/After optimization comparison
- Grafana charts với metrics: RPS, latency p95/p99, CPU/Memory

### 3. Hiện thực hóa Tối ưu (20% điểm)

**Deliverables**:

- Spring Cache + Redis
- Terraform Auto Scaling policies
- RDS Read Replica
- Circuit Breaker pattern

---

## 🔬 Testing Strategy (Instructor Confirmed)

**Primary Environment**: Local Docker Compose

- Load testing với k6 trên local
- Grafana dashboards cho before/after charts
- Cost: $0

**AWS Terraform**: Design validation only

- `terraform plan` để validate infrastructure code
- Code production-ready nhưng không deploy
- Rationale: Tập trung vào thiết kế, không cần chi phí AWS

---

## 👥 Phân công Công việc

### Role A - Nguyễn Việt Khoa (Backend)

**Focus**: Code optimization + Load testing

**Deliverables**:

- Spring Cache implementation (TripService)
- Resilience4j Circuit Breaker (DriverService calls)
- HikariCP connection pool tuning
- RestTemplate HTTP client pooling
- 4 k6 load testing scripts
- Before/After test results với Grafana screenshots
- 4 ADRs: 013-016

### Role B - Nguyễn Quốc Bảo (Platform)

**Focus**: Infrastructure design + Architecture

**Deliverables**:

- Security Group segregation (8 SGs)
- ECS Auto Scaling policies (CPU/Memory targets)
- RDS Read Replica design
- Redis backup configuration
- Async architecture diagram (SQS)
- 4 ADRs: 017-020
- ARCHITECTURE.md Module A section
- REPORT.md coordination

---

## 📅 Timeline (Critical Path)

### Week 9: Infrastructure Foundation

- **Role B**: Complete Tasks B.1-B.4 (Terraform code)
- **Role A**: Start Task A.1-A.2 (Spring Cache, Circuit Breaker)
- **Sync**: Validate Terraform code với `terraform plan`

### Week 10: Code Optimization

- **Role A**: Complete Tasks A.3-A.4 (Connection pool, HTTP client)
- **Role B**: Start Tasks B.5-B.6 (Async design, ADRs)
- **Sync**: Review caching implementation

### Week 11: Load Testing Phase

- **Role A**: Tasks A.5-A.6 (k6 scripts, BEFORE tests)
- **Role B**: Complete Tasks B.6-B.7 (ADRs, ARCHITECTURE.md)
- **Sync**: Review bottleneck analysis

### Week 12: Validation & Documentation

- **Role A**: Task A.7 (AFTER tests), A.8-A.9 (ADRs, Demo prep)
- **Role B**: Tasks B.9-B.10 (CloudWatch design, REPORT.md)
- **Sync**: Finalize all deliverables

---

## 📦 Deliverables Checklist

### Code & Configuration

- [ ] Spring Cache (A.1)
- [ ] Circuit Breaker (A.2)
- [ ] Connection pool (A.3)
- [ ] HTTP client pool (A.4)
- [ ] Auto-scaling Terraform (B.2)
- [ ] Security Groups (B.1)
- [ ] Read Replica (B.3)

### Load Testing

- [ ] 4 k6 scenarios (A.5)
- [ ] Before results + charts (A.6)
- [ ] After results + charts (A.7)

### Documentation

- [ ] 8 ADRs total (A.8, B.6)
- [ ] ARCHITECTURE.md update (B.7)
- [ ] REPORT.md Module A section (B.10)
- [ ] Async architecture diagram (B.5)

### Presentation

- [ ] Demo slides
- [ ] Load testing live demo
- [ ] Architecture evolution explanation

---

## 🎯 Expected Outcomes

### Performance Metrics (Target)

- **Throughput**: 100 RPS → 500+ RPS (5x improvement)
- **Latency p95**: < 200ms cho trip search
- **Cache Hit Rate**: > 80% cho trip history
- **Auto-scaling**: 1→5 tasks trong 2 phút @ CPU 70%

### Cost Analysis

- Local testing: $0
- Auto-scaling: -30% cost @ low traffic
- Read replica: +50% RDS cost, -70% primary load

---

## ⚠️ Risk Mitigation

| Risk                         | Mitigation                                          |
| ---------------------------- | --------------------------------------------------- |
| Auto-scaling không hoạt động | Validate Terraform code, monitor CloudWatch metrics |
| Load testing crash services  | Incremental load increase, test on local first      |
| Cache invalidation bugs      | Integration tests cho cache logic                   |
| Merge conflicts              | Frequent commits, PR reviews                        |

---

## 📁 Folder Structure

```
docs/module-a/
├── PLAN.md                          # This file
├── ROLE_A_TASKS.md                  # Backend task checklist
├── ROLE_B_TASKS.md                  # Platform task checklist
├── load-testing/
│   ├── scenarios/                   # k6 scripts
│   └── results/                     # Before/After screenshots
└── diagrams/                        # Architecture diagrams

docs/adr/
├── 00x-basic/                       # ADRs 001-012 (Phase 1)
└── 01x-module-a/                    # ADRs 017-020 (Module A)

terraform/modules/
├── database/                        # Updated by Role B
└── ecs/                             # Updated by Role B

{user|trip}-service/                 # Updated by Role A
```

---

**Status**: 🟢 In Progress (Week 11)  
**Last Updated**: 2025-11-22
