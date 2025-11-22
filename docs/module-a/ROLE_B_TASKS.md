# Role B: Platform Engineer Tasks (Nguyễn Quốc Bảo)

## 🎯 Your Focus

- Infrastructure optimization (Terraform)
- Architecture design & documentation
- **Deliverables**: 4 ADRs, Terraform modules, diagrams, ARCHITECTURE.md, REPORT.md

---

## 📅 Week 9-10: Infrastructure Optimization

### Task B.1: Security Group Segregation ⏱️ Week 9

**Goal**: Tách SG theo principle of least privilege

**Current Problem**: 1 SG cho tất cả services → vi phạm security best practice

**Solution**: 8 Security Groups riêng biệt

**Steps**:

1. Create trong `terraform/modules/database/main.tf`:
   - `user_db_sg`: Chỉ cho phép từ `user_service_sg`
   - `trip_db_sg`: Chỉ cho phép từ `trip_service_sg`
   - `redis_sg`: Chỉ cho phép từ `driver_service_sg`
2. Create trong `terraform/modules/network/main.tf`:
   - `alb_sg`: Ingress 80/443, egress to service SGs
3. Create trong `terraform/modules/ecs/main.tf`:

   - `user_service_sg`: Ingress từ ALB, egress to user_db_sg
   - `trip_service_sg`: Ingress từ ALB, egress to trip_db_sg
   - `driver_service_sg`: Ingress từ ALB, egress to redis_sg
   - Remove old `db_access` SG

4. Update ECS services để reference SG mới

**Acceptance Criteria**:

- [ ] `terraform plan` shows 8 new SGs, 1 deletion
- [ ] Each service chỉ access DB của nó
- [ ] Security rules follow least privilege

**Files**:

- `terraform/modules/database/main.tf` (3 SGs)
- `terraform/modules/network/main.tf` (1 SG)
- `terraform/modules/ecs/main.tf` (3 SGs + service updates)

**Status**: ✅ Completed (Committed to feat/module-a-security-groups)

---

### Task B.2: ECS Auto Scaling ⏱️ Week 9

**Goal**: Scale tasks based on CPU/Memory/Request metrics

**Steps**:

1. Add trong `terraform/modules/ecs/main.tf`:

   ```hcl
   resource "aws_appautoscaling_target" "user_service" {
     service_namespace  = "ecs"
     resource_id        = "service/${var.cluster_name}/${aws_ecs_service.user_service.name}"
     scalable_dimension = "ecs:service:DesiredCount"
     min_capacity       = 1
     max_capacity       = 10
   }
   ```

2. Add 3 scaling policies cho mỗi service:

   - **CPU Target Tracking**: Target 70%
   - **Memory Target Tracking**: Target 80%
   - **ALB Request Count**: Target 1000 requests/target/minute

3. Repeat cho trip-service và driver-service (9 policies total)

**Acceptance Criteria**:

- [ ] `terraform plan` shows 3 targets + 9 policies
- [ ] Min: 1, Max: 10 tasks
- [ ] Scale-out threshold: CPU > 70% OR Memory > 80%
- [ ] Scale-in after 5 minutes below threshold

**Files**: `terraform/modules/ecs/main.tf`

**Status**: ✅ Completed (Committed to feat/module-a-security-groups)

---

### Task B.3: RDS Read Replica ⏱️ Week 9

**Goal**: Offload read queries từ primary DB

**Steps**:

1. Add trong `terraform/modules/database/main.tf`:

   ```hcl
   resource "aws_db_instance" "trip_db_read_replica" {
     replicate_source_db    = aws_db_instance.trip_db.identifier
     instance_class         = "db.t3.micro"
     identifier             = "uit-go-trip-db-replica"
     publicly_accessible    = false
     skip_final_snapshot    = true
     vpc_security_group_ids = [aws_security_group.trip_db_sg.id]
   }
   ```

2. Add output cho read replica endpoint:

   ```hcl
   output "trip_db_read_endpoint" {
     value = aws_db_instance.trip_db_read_replica.endpoint
   }
   ```

3. Document usage trong `docs/module-a/PLAN.md`:
   - Use read endpoint cho `getPassengerHistory()`, `getDriverHistory()`
   - Use write endpoint cho `createTrip()`, `updateTripStatus()`

**Acceptance Criteria**:

- [ ] `terraform plan` shows read replica creation
- [ ] Same VPC, same SG as primary
- [ ] Endpoint exported cho application config

**Files**: `terraform/modules/database/main.tf`, `terraform/outputs.tf`

**Status**: ✅ Completed (Committed to feat/module-a-security-groups)

---

### Task B.4: Redis Backup Configuration ⏱️ Week 9

**Goal**: Enable snapshot retention cho disaster recovery

**Steps**:

1. Update `aws_elasticache_cluster.driver_cache` trong `terraform/modules/database/main.tf`:

   ```hcl
   resource "aws_elasticache_cluster" "driver_cache" {
     # ... existing config ...
     snapshot_retention_limit = 5
     snapshot_window         = "03:00-05:00"  # UTC
     maintenance_window      = "sun:05:00-sun:07:00"
   }
   ```

2. Add output:
   ```hcl
   output "redis_snapshot_retention" {
     value = aws_elasticache_cluster.driver_cache.snapshot_retention_limit
   }
   ```

**Acceptance Criteria**:

- [ ] `terraform plan` shows snapshot config
- [ ] 5-day retention
- [ ] Backup window không overlap với peak traffic

**Files**: `terraform/modules/database/main.tf`

**Status**: ✅ Completed (Committed to feat/module-a-security-groups)

---

## 📅 Week 11: Architecture & Documentation

### Task B.5: Async Architecture Design (SQS) ⏱️ Week 11

**Goal**: Design async communication cho trip creation flow

**Steps**:

1. Create diagram trong `docs/module-a/diagrams/async-architecture.drawio`:
   - **Synchronous Flow** (current): Client → TripService → DriverService → Response
   - **Asynchronous Flow** (proposed): Client → TripService → SQS → Lambda/Worker → DriverService
2. Document trade-offs:

   - ✅ Pros: Decoupling, retry logic, better fault tolerance
   - ❌ Cons: Increased latency, complexity, eventual consistency

3. Export PNG: `async-architecture.png`

**Acceptance Criteria**:

- [ ] Both architectures visualized
- [ ] Components labeled: ALB, ECS, SQS, Lambda
- [ ] Clear comparison trong ADR-020

**Files**: `docs/module-a/diagrams/async-architecture.{drawio,png}`

---

### Task B.6: Viết 4 ADRs ⏱️ Week 11

**Goal**: Document infrastructure decisions

**ADRs**:

1. **ADR-017**: Security Group Segregation
   - Context: Shared SG = security risk
   - Decision: 8 SGs theo service/DB
   - Trade-offs: More SGs vs Better security
2. **ADR-018**: Auto Scaling Strategy
   - Context: Fixed task count → waste or insufficient
   - Decision: Target tracking (CPU 70%, Memory 80%)
   - Trade-offs: Cost vs Availability
3. **ADR-019**: RDS Read Replica vs Caching
   - Context: Read-heavy workload bottleneck
   - Decision: Defense-in-depth (Both cache + replica)
   - Trade-offs: Cost vs Performance
4. **ADR-020**: Async Communication (SQS)
   - Context: Tight coupling between services
   - Decision: Design SQS-based async flow (NOT implemented)
   - Trade-offs: Latency vs Resilience

**Template**: Use format from `docs/adr/00x-basic/001-*.md`

**Sections Required**:

- Status, Context, Decision, Consequences, Alternatives Considered

**Acceptance Criteria**:

- [ ] All 4 ADRs trong `docs/adr/01x-module-a/`
- [ ] Trade-offs explained với pros/cons
- [ ] References to Terraform code

**Files**: `docs/adr/01x-module-a/017-*.md` through `020-*.md`

**Status**: ✅ Completed (On feat/module-a-documentation branch)

---

### Task B.7: Update ARCHITECTURE.md ⏱️ Week 11

**Goal**: Add Module A enhancements section

**Steps**:

1. Add section: `## Module A: Scalability Enhancements`
2. Subsections:
   - Security architecture (8 SGs diagram)
   - Auto-scaling policies (CloudWatch metrics diagram)
   - Read replica topology (primary/replica flow)
   - Async architecture (reference Task B.5 diagram)
3. Link to ADRs 017-020
4. Add before/after architecture comparison

**Acceptance Criteria**:

- [ ] Section fits existing document structure
- [ ] Diagrams referenced/embedded
- [ ] Links to all Module A ADRs

**Files**: `docs/ARCHITECTURE.md`

---

## 📅 Week 12: Validation & Final Docs

### Task B.9: CloudWatch Alarms Design ⏱️ Week 12

**Goal**: Design monitoring alerts (Terraform code only, not deployed)

**Steps**:

1. Create `terraform/modules/ecs/cloudwatch.tf`:

   ```hcl
   resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
     alarm_name          = "uit-go-ecs-cpu-high"
     comparison_operator = "GreaterThanThreshold"
     evaluation_periods  = "2"
     metric_name         = "CPUUtilization"
     namespace           = "AWS/ECS"
     period              = "60"
     statistic           = "Average"
     threshold           = "80"
     alarm_description   = "Triggers when ECS CPU > 80%"
   }
   ```

2. Add alarms:
   - CPU > 80% (trigger auto-scaling)
   - Memory > 85%
   - ECS task failure rate > 10%
   - RDS connection saturation > 90%

**Acceptance Criteria**:

- [ ] `terraform plan` shows 4 alarms
- [ ] Thresholds aligned với scaling policies
- [ ] Would trigger SNS topic (if deployed)

**Files**: `terraform/modules/ecs/cloudwatch.tf` (new file)

---

### Task B.10: Complete REPORT.md Module A Section ⏱️ Week 12

**Goal**: Write final Module A analysis cho submission

**Sections to Complete**:

1. **Section 2: Phân tích Module chuyên sâu**
   - Describe approach: Local testing + Terraform validation
   - Explain instructor confirmation (no AWS deployment)
2. **Section 3: Tổng hợp Quyết định & Trade-offs**
   - Summarize 8 ADRs (013-020)
   - Key trade-offs table:
     | Decision | Pro | Con | Rationale |
   - Reference load testing results from Role A
3. **Section 4: Thách thức & Bài học**
   - AWS cost constraints → Terraform design-only approach
   - Security group complexity → Better isolation
4. **Section 5: Kết quả & Hướng phát triển**
   - Performance improvements (from Role A's charts)
   - Future: Implement SQS async flow (ADR-020)

**Coordinate with Role A**:

- Get load testing results
- Review ADRs 013-016
- Align on final metrics

**Acceptance Criteria**:

- [ ] 3-5 pages total
- [ ] All sections complete
- [ ] Charts/diagrams embedded
- [ ] Professional formatting

**Files**: `docs/REPORT.md`

---

## 🎯 Success Metrics

Your infrastructure should enable:

- **Auto-scaling**: 1→10 tasks based on load
- **Security**: Zero cross-service DB access
- **Availability**: Read replica reduces primary load by 70%
- **Observability**: CloudWatch alarms ready to deploy

---

## 📁 Your Deliverables Summary

| Item                       | Location                                    | Status |
| -------------------------- | ------------------------------------------- | ------ |
| Security Groups (8)        | `terraform/modules/{database,network,ecs}/` | ✅     |
| Auto-scaling policies      | `terraform/modules/ecs/main.tf`             | ✅     |
| Read replica               | `terraform/modules/database/main.tf`        | ✅     |
| Redis backup config        | `terraform/modules/database/main.tf`        | ✅     |
| Async architecture diagram | `docs/module-a/diagrams/`                   | ⏳     |
| ADRs 017-020               | `docs/adr/01x-module-a/`                    | ✅     |
| ARCHITECTURE.md update     | `docs/ARCHITECTURE.md`                      | ⏳     |
| CloudWatch alarms          | `terraform/modules/ecs/cloudwatch.tf`       | ⏳     |
| REPORT.md Module A         | `docs/REPORT.md`                            | ⏳     |

---

**Dependencies**: Coordinate với Role A cho load testing results  
**Sync Points**: End of Week 9, Week 10, Week 11, Week 12
