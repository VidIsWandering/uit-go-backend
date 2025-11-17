# AWS Deployment Strategy - Module A

## 📌 Tóm tắt Chiến lược

**Quyết định hiện tại**: Phát triển và kiểm chứng trên **Local Docker Compose** trước

- ✅ Lập trình Terraform code (production-ready)
- ✅ Validate với `terraform plan`
- ✅ Load testing trên local environment
- ✅ So sánh kết quả before/after (relative improvements)
- **Chi phí**: $0

**Tùy chọn tương lai**: Deploy lên AWS nếu giảng viên yêu cầu

- ⏰ Deploy trong 1 ngày (morning → afternoon)
- 📸 Screenshot/video cho báo cáo
- 🗑️ Destroy ngay sau đó
- **Chi phí**: ~$5-8 cho 1 ngày

---

## ❓ Câu hỏi cần hỏi Giảng viên

### Câu hỏi chính:

> **"Thầy/Cô ơi, em có thắc mắc về Load Testing cho Module A:**
>
> Do AWS Free Tier đã hết quota (ALB creation bị block), nếu deploy liên tục sẽ tốn ~$57/tháng. Em thấy trong slide giảng viên nói "chỉ cần có experience với AWS deployment".
>
> Em đề xuất 2 phương án:
>
> 1. **Load testing trên Local Docker Compose**
>
>    - Test được performance improvements (cache, circuit breaker)
>    - So sánh được kết quả before/after optimization
>    - Terraform code vẫn viết đầy đủ (production-ready)
>    - Chi phí: $0
>
> 2. **Deploy AWS chỉ 1 ngày (demo day)**
>    - Buổi sáng: Deploy infrastructure (~3 giờ)
>    - Chạy quick load test
>    - Screenshot, record video
>    - Buổi chiều: Destroy ngay
>    - Chi phí: ~$5-8
>
> **Thầy/Cô chấp nhận phương án nào ạ?** Hay phải deploy AWS liên tục?"

---

## 📊 So sánh 3 Chiến lược

| Criteria                  | Strategy 1: Local Only | Strategy 2: 1-Day AWS Deploy | Strategy 3: Continuous AWS |
| ------------------------- | ---------------------- | ---------------------------- | -------------------------- |
| **Chi phí**               | $0                     | $5-8                         | $57/tháng                  |
| **Load Testing**          | Local Docker Compose   | AWS (quick tests)            | AWS (full scenarios)       |
| **Terraform Validation**  | `terraform plan` only  | `terraform apply` (1 day)    | `terraform apply` (24/7)   |
| **Screenshots/Video**     | Local environment      | Real AWS                     | Real AWS                   |
| **Learning Value**        | ⭐⭐⭐ (code + IaC)    | ⭐⭐⭐⭐ (code + IaC + AWS)  | ⭐⭐⭐⭐ (full experience) |
| **Risk**                  | Không rủi ro           | Thấp (deploy 1 ngày)         | Cao (vượt ngân sách)       |
| **Deliverables Complete** | ✅ (trừ AWS evidence)  | ✅ (đủ hết)                  | ✅ (đủ hết)                |

---

## ✅ Kế hoạch Hiện tại (Pending Instructor Confirmation)

### Phase 1 (Week 9-12): Local Development

**Role A Tasks**:

- [ ] Implement Spring Cache, Circuit Breaker, Connection Pooling
- [ ] Write k6 load testing scripts (4 scenarios)
- [ ] Run load tests **on local Docker Compose**
- [ ] Document results: before vs after optimization
- [ ] Write 4 ADRs (013-016)

**Role B Tasks**:

- [ ] Write Terraform code: Auto-scaling, SG segregation, Read Replica
- [ ] **Validate** with `terraform plan` (NOT deploy)
- [ ] Create VALIDATION_REPORT.md
- [ ] Design async architecture (SQS)
- [ ] Write 4 ADRs (017-020)

**Deliverables**:

- ✅ Terraform code (production-ready, committed to git)
- ✅ Load testing results (local environment)
- ✅ 8 ADRs
- ✅ Updated ARCHITECTURE.md, REPORT.md
- ⏳ AWS screenshots/video (pending instructor decision)

---

### Phase 2 (Optional): 1-Day AWS Deployment

**If instructor requires AWS evidence**, chúng em sẽ thực hiện:

**Timeline**: 1 ngày (Week 12, trước deadline)

**Morning** (8:00 AM - 12:00 PM):

```bash
# 1. Deploy infrastructure (20 min)
cd terraform
terraform apply module-a.tfplan

# 2. Build & push Docker images (30 min)
docker build -t <ECR>/user-service:v2 user-service/
docker build -t <ECR>/trip-service:v2 trip-service/
docker build -t <ECR>/driver-service:v2 driver-service/
docker push ...

# 3. Update ECS task definitions (10 min)
# 4. Wait for auto-scaling stabilization (30 min)

# 5. Run quick load tests (60 min)
k6 run load-testing/scripts/scenario-1-baseline.js
k6 run load-testing/scripts/scenario-2-create-trip.js
...

# 6. Take screenshots & record video (30 min)
# - Grafana dashboards
# - CloudWatch metrics
# - ECS auto-scaling in action
# - Load testing output
```

**Afternoon** (1:00 PM - 5:00 PM):

```bash
# 7. Clean up EVERYTHING (10 min)
terraform destroy -auto-approve

# 8. Verify no resources left (5 min)
aws ecs list-clusters
aws rds describe-db-instances
aws elasticache describe-cache-clusters
```

**Cost Breakdown**:

- ECS Fargate (3 services × 2 tasks × 4 hours): ~$1.50
- RDS (2 instances × 4 hours): ~$0.80
- ElastiCache (1 node × 4 hours): ~$0.40
- ALB (4 hours): ~$0.04
- NAT Gateway (4 hours × 2 AZs): ~$2.00
- CloudWatch (minimal): ~$0.10
- **Total**: ~$5-8

**Evidence for Report**:

- ✅ Screenshots: CloudWatch, Grafana, ECS Console
- ✅ Video: Auto-scaling demo (CPU spike → scale to 10 tasks → scale down)
- ✅ Load testing results: AWS production metrics
- ✅ Terraform apply/destroy logs

---

## 🔄 Chuyển đổi từ Local sang AWS

### Step 1: Update k6 scripts

**Before** (Local):

```javascript
const BASE_URL = "http://localhost:8080";
```

**After** (AWS):

```javascript
const BASE_URL = "http://uit-go-alb-123456789.ap-southeast-1.elb.amazonaws.com";
```

### Step 2: Update application config

**Before** (Local):

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/user_db
spring.redis.host=localhost
```

**After** (AWS - auto-injected via ECS environment variables):

```properties
spring.datasource.url=jdbc:postgresql://${DB_HOST}:5432/${DB_NAME}
spring.redis.host=${REDIS_HOST}
```

### Step 3: Run terraform

```bash
cd terraform
terraform plan -out=module-a.tfplan
terraform apply module-a.tfplan
```

### Step 4: Re-run load tests

```bash
# Same scripts, different BASE_URL
k6 run load-testing/scripts/scenario-1-baseline.js
...
```

---

## 📝 Script hỏi Giảng viên (Vietnamese)

**Bối cảnh**:

- Nhóm em đã hoàn thành Phase 1 (basic microservices deployment)
- Đang vào Module A (Scalability & Performance)
- AWS Free Tier hết quota ALB, deploy liên tục sẽ tốn $57/tháng

**Câu hỏi**:

> "Thầy/Cô ơi, em có thắc mắc về Load Testing cho Module A.
>
> Hiện tại AWS Free Tier của em đã block việc tạo ALB (hết quota). Nếu deploy liên tục sẽ tốn khoảng $57/tháng (chủ yếu là NAT Gateway $32 + Fargate $9 + ALB $16).
>
> Em nhớ trong slide Thầy/Cô nói **'chỉ cần có experience với AWS deployment, không yêu cầu chạy 24/7'**.
>
> Nên em đề xuất:
>
> 1. **Phát triển và test trên Local trước** (Week 9-12):
>
>    - Viết đầy đủ Terraform code (production-ready)
>    - Implement caching, circuit breaker, auto-scaling config
>    - Load testing trên Docker Compose (kết quả relative improvements vẫn valid)
>    - Cost: $0
>
> 2. **Deploy AWS chỉ 1 ngày** (trước deadline):
>    - Buổi sáng: `terraform apply` + chạy load test + screenshot
>    - Buổi chiều: `terraform destroy` ngay
>    - Cost: ~$5-8
>
> **Cách này có được không ạ Thầy/Cô?** Hay nhóm em phải deploy liên tục trên AWS?"

**Expected Answer**:

- ✅ "Được, các em cứ test local trước. Khi nào demo thì deploy 1 ngày cho em chụp màn hình là đủ."
- ⚠️ "Không, các em phải deploy liên tục để monitor được metrics theo thời gian thực."

**If Thầy/Cô says YES (Strategy 2)**:

- → Proceed with Local Testing (current plan)
- → Schedule 1-day AWS deployment (Week 12)
- → Update ROLE_A_TASKS.md, ROLE_B_TASKS.md to reflect "AWS Migration Day"

**If Thầy/Cô says NO (Strategy 3)**:

- → Need budget discussion với gia đình
- → OR find sponsor/credits (AWS Educate, GitHub Student Pack)
- → OR reduce cost: single-AZ, t4g.micro, no NAT Gateway

---

## 🎯 Recommendation (My Opinion)

**Best Approach**: Strategy 2 (1-Day AWS Deploy)

**Lý do**:

1. ✅ **Learning Value**: Vẫn deploy thật lên AWS (Terraform apply/destroy experience)
2. ✅ **Cost-Effective**: Chỉ $5-8 thay vì $57/tháng
3. ✅ **Real Evidence**: Screenshots/video từ AWS production (không phải fake)
4. ✅ **Time-Efficient**: Không phải maintain infrastructure 24/7
5. ✅ **Risk Mitigation**: Không lo vượt budget học sinh

**Tradeoff**:

- ❌ Không có long-term monitoring data (7-day CloudWatch charts)
- ❌ Không test được auto-scaling trong production traffic thực
- ✅ Nhưng giảng viên chấp nhận vì "chỉ cần experience"

---

## 📅 Next Steps

1. **Hôm nay**: Continue với Local Testing strategy

   - Role A: Code optimization
   - Role B: Terraform code development

2. **Buổi học tới**: Hỏi giảng viên về deployment strategy

   - Mang theo document này
   - Giải thích cost breakdown ($0 vs $5-8 vs $57)

3. **After instructor confirmation**:
   - ✅ If YES (1-day deploy): Update plan, schedule AWS Deploy Day
   - ⚠️ If NO (continuous deploy): Discuss budget, find alternatives

---

**Last Updated**: 2025-11-17
**Status**: ⏳ Pending Instructor Confirmation
**Decision Maker**: Giảng viên SE360
