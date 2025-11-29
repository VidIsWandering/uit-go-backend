# Module A – Hybrid Zero-Cost Strategy & Cloud Deployment Readiness

## 1. Mục tiêu
- Đảm bảo kiến trúc có thể triển khai lên AWS khi có ngân sách.
- Hiện tại dùng "Hybrid Zero-Cost": mô phỏng tài nguyên tốn phí bằng local containers / tooling, chỉ giữ lại phần tài liệu + kịch bản xác minh.
- Chuẩn bị sẵn toggle (design) để bật tài nguyên thật khi chuyển sang giai đoạn trả phí.

## 2. Phân loại tài nguyên theo chi phí
| Thành phần | Trạng thái Hybrid | AWS Thật (sau này) | Lý do trì hoãn |
|------------|------------------|--------------------|---------------|
| VPC / Subnets / SG | Chỉ mô tả (chưa tạo) | Tạo bằng Terraform | Không cần cho load test local |
| RDS PostgreSQL Primary | Mô phỏng bằng Postgres Docker | `db.t3.micro` (Free Tier 750h) | Tránh tiêu thụ Free Tier cho nhiều instance nếu không cần |
| RDS Read Replica | Mô phỏng bằng container thứ hai / logical replication | `db.t3.micro` khác AZ | Phát sinh thêm chi phí ngoài Free Tier |
| ElastiCache Redis | Mô phỏng bằng Redis Docker | `cache.t3.micro` | Không Free Tier thực sự |
| SQS Queue | (Tùy chọn) Có thể tạo thật – Free Tier 1M requests | `aws_sqs_queue` | Chi phí ~0, có giá trị xác thực async |
| ECS Fargate Cluster | Mô phỏng bằng Docker Compose / kind | Fargate tasks (256/512) | Fargate tính phí theo vCPU+RAM |
| ALB | Mô phỏng bằng Nginx reverse proxy | `aws_lb` + listener | ALB tính phí giờ + LCU |
| Service Discovery (Cloud Map) | Hardcoded hostnames local | Private DNS Namespace | Chưa cần cho PoC local |
| Auto Scaling Policies | Mô phỏng bằng script scale containers | `aws_appautoscaling_*` | Cần traffic thật + metrics |
| Secrets Manager | Môi trường `.env` / Docker secrets | `aws_secretsmanager_secret` | Secrets Manager có phí nhỏ/tháng |
| ECR | Tuỳ chọn (chưa cần) | Repository scan_on_push | Local build đủ cho PoC |
| CloudWatch Logs | Log về console / file | Log groups per service | Tránh ingest phí |
| Prometheus/Grafana | Local stack | (Tùy chọn) Managed / self-host EC2 | Tiết kiệm chi phí compute |

## 3. Thiết kế Toggle (dự kiến – chưa áp dụng code)
Đề xuất thêm các biến boolean:
```
variable "enable_rds"            { default = false }
variable "enable_read_replica"   { default = false }
variable "enable_elasticache"    { default = false }
variable "enable_ecs"            { default = false }
variable "enable_alb"            { default = false }
variable "enable_service_discovery" { default = false }
variable "enable_autoscaling"    { default = false }
variable "enable_ecr"            { default = false }
variable "enable_sqs"            { default = false }
```
Áp dụng: thêm `count = var.enable_rds ? 1 : 0` vào resource nhóm RDS; điều kiện hóa outputs: `value = var.enable_rds ? aws_db_instance.user_db[0].address : ""`.

## 4. Cách mô phỏng local (zero-cost)
| Tính năng | Giải pháp local | Ghi chú |
|-----------|-----------------|--------|
| Read/Write Split | 2 Postgres containers: `primary`, `replica_sim` | Replica sync thô bằng cron dump/restore hoặc logical replication nếu cần |
| Async Queue | Local Redis List / hoặc SQS thật (0 chi phí) | Dùng SQS thật nếu muốn validate SDK |
| Caching | Redis container | Áp dụng cache aside trong user-service |
| Autoscaling | Script scale: `docker compose up --scale trip-service=5` | K6 tạo tải để đo p95/p99 |
| Service Discovery | Docker network + static hostnames | Không cần Cloud Map |
| Observability | Prometheus + Grafana containers | Dashboard mô phỏng CPU, latency, queue depth |

## 5. Load Test Round 2 (Hybrid Plan)
- Tỷ lệ traffic: 85% GET (đọc replica), 15% POST (tạo trip).
- Mục tiêu cải thiện: p95 giảm ≥ 20% so với Round 1; error rate < 1%; throughput tăng ≥ 30%.
- Thu thập metrics: 
  - Postgres: active connections primary vs replica_sim
  - Cache hit rate user-service
  - Queue lag (nếu dùng SQS thật) / consumer processing time
  - GC pauses (Java) / heap usage.

## 6. Ước tính chi phí triển khai thật (ap-southeast-1 – tham khảo)
| Thành phần | Loại | Ước tính / tháng (USD) | Ghi chú |
|------------|------|------------------------|--------|
| RDS PostgreSQL `db.t3.micro` | Compute + Storage (Free Tier 750h) | ~0 (nếu trong Free Tier) / ~15–20 hết Free Tier | Replica thêm ~15–20 |
| ElastiCache Redis `cache.t3.micro` | Node | ~15–18 | Không free |
| SQS | 1M requests free | ~0 | Vượt ngưỡng: $0.40 / 1M |
| ECS Fargate (256/512) | 3 services * 1 task | ~ (0.01269 vCPU + 0.00137 GB-s) * giờ * số task → ~25–40 | Tùy thời lượng chạy |
| ALB | Base + LCU | ~18–25 | Phụ thuộc request count |
| Secrets Manager | 2 secrets | ~$0.80 | $0.40/secret/tháng |
| CloudWatch Logs | Nhỏ | ~$1–5 | Tùy ingest |
| ECR Storage | <500MB | ~0 | Free tier |
| Data Transfer | Minimal | ~0–5 | Tùy traffic |
| Tổng (không replica) |  | ~80–115 | Dao động |
| Tổng (có replica + Redis) |  | ~110–150 | Thêm replica + Redis |

(Lưu ý: Con số chỉ mang tính tham khảo, cần kiểm chứng bằng AWS Pricing Calculator.)

## 7. Lộ trình nâng cấp từ Hybrid → Cloud
| Giai đoạn | Mục tiêu | Hành động |
|-----------|----------|-----------|
| Pha 1 | Xác thực logic | Chỉ local + tài liệu kiến trúc |
| Pha 2 | Partial deploy chi phí thấp | Bật SQS + (tùy chọn) RDS primary |
| Pha 3 | Đo hiệu năng thực | Bật ECS + ALB + quan sát CloudWatch |
| Pha 4 | Tối ưu đọc | Thêm Read Replica, connection pooling tune |
| Pha 5 | Hardening & Scale | Bật autoscaling, secrets rotation, chaos test |

## 8. Rủi ro nếu chỉ tài liệu mà không deploy
| Rủi ro | Tác động | Giảm thiểu (Hybrid) |
|--------|----------|---------------------|
| Network configs sai (CIDR, SG) | Fail khi deploy | Terraform validate syntax sớm, review manual |
| IAM thiếu quyền PassRole | ECS tasks không start | Ghi rõ policy mẫu trong tài liệu |
| Connection pool & replica lag thực khác mô phỏng | Sai số tuning | Ghi baseline giả lập, so sánh khi có budget |
| Autoscaling thresholds không thực tế | Scale bất ngờ / thừa | Mô phỏng giới hạn CPU local + ghi chú giả định |

## 9. Bằng chứng Cloud-ready (dành cho người chấm)
- Có Terraform modules đầy đủ: network, database, ecs, sqs.
- Có chiến lược toggle để giảm chi phí ban đầu.
- Code đã hỗ trợ read/write split bằng `RoutingDataSource` + `@Transactional(readOnly = true)`.
- Tài liệu mô tả chi phí, lộ trình, rủi ro, và tiêu chí thành công.

## 10. Khi bật thật – Checklist nhanh
- [ ] Tạo IAM user tối giản + policy PassRole cho ECS.
- [ ] Bật `enable_rds=true` trước, kiểm tra kết nối.
- [ ] Import dữ liệu seed (nếu cần) qua task init container.
- [ ] Bật SQS để chuyển từ local mock.
- [ ] Xây image thật (build & push ECR) thay placeholder `nginx:latest`.
- [ ] Bật ECS + ALB + health checks.
- [ ] Xác minh logs CloudWatch nhóm `/ecs/*` xuất hiện.
- [ ] Thêm replica rồi chuyển traffic GET sang READ (đã sẵn code annotation).
- [ ] Bật autoscaling final sau khi có baseline CPU/memory.

## 11. Định nghĩa tiêu chí "Ready for Cloud"
| Tiêu chí | Mức đạt | Bằng chứng |
|----------|---------|------------|
| IaC đầy đủ | Có modules Terraform | Repo + file này |
| Read/Write Split | Annotate + config | DataSourceConfig + TripController |
| Async queue chuẩn | SQS plan + local mock | Module sqs + kịch bản produce/consume |
| Cache chiến lược | User-service caching + doc | Annotation + metrics kế hoạch |
| Observability tối thiểu | Prometheus local + plan CloudWatch | Dashboard local |
| Chi phí minh bạch | Bảng cost ước tính | Mục 6 |
| Lộ trình mở rộng | Pha 1–5 rõ ràng | Mục 7 |

## 12. Gợi ý tối ưu chi phí khi triển khai thật
- Dùng RDS Single AZ trước; replica chỉ bật khi READ QPS > ~300 và primary CPU > 60%.
- Gom log ứng dụng không quan trọng vào một log group để giảm chi phí lưu trữ.
- Dùng SQS long polling (đã `receive_wait_time_seconds=10`) để giảm API calls.
- Bật compression ở layer HTTP gateway (ALB → bật Gzip/Brotli nếu ALB hỗ trợ trá hình qua ứng dụng).
- Cân nhắc chuyển Secrets Manager sang SSM Parameter Store với dữ liệu ít thay đổi.

## 13. Công việc còn lại (Follow-up)
| Task | Trạng thái |
|------|------------|
| Thêm biến toggle vào Terraform (chưa code) | Pending |
| Cập nhật README hướng dẫn Hybrid vs Cloud | Pending |
| Load Test Round 2 (kịch bản GET-heavy) | Planned |
| Ghi kết quả Round 2 vào `results/` | Planned |
| Thêm cost calculator link vào docs | Optional |

## 14. Kết luận
Chiến lược Hybrid Zero-Cost giúp tránh chi phí ngay bây giờ nhưng vẫn chứng minh đầy đủ tính Cloud-ready: kiến trúc, source code hỗ trợ scaling, tài liệu chi phí và lộ trình nâng cấp. Khi có ngân sách, chỉ cần bật các toggle và apply Terraform tuần tự theo checklist.

---
*File được sinh tự động để phục vụ Module A – Cloud Readiness.*
