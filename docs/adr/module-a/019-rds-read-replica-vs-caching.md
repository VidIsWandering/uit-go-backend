# ADR 019: RDS Read Replica cho Trip History Queries

## Trạng thái

Được chấp nhận (Accepted)

## Bối cảnh

Trip history queries là tác vụ đọc nặng với tỷ lệ write:read = 1:100. Mỗi trip được tạo 1 lần (INSERT), nhưng được query nhiều lần (user xem lịch sử, analytics, reporting).

**Vấn đề hiện tại (Baseline Analysis):**

- Primary RDS instance (trip_db) xử lý cả reads và writes
- Query load: ~90% reads, 10% writes (tính chất điển hình của tác vụ đọc nặng)
- Latency trip history: ~800ms p95 (estimated - slow SELECT với JOIN)
- Database connections: Risk of saturation under load
- CPU Utilization: Expected bottleneck @ 75% sustained

**Note**: Metrics based on typical microservices patterns, to be validated via load testing

**Query patterns:**

```sql
-- Write (10% traffic): CREATE trip
INSERT INTO trips (user_id, driver_id, status, ...) VALUES (...);

-- Read (90% traffic): Trip history, pagination, filtering
SELECT t.*, u.name, d.name
FROM trips t
JOIN users u ON t.user_id = u.id
JOIN drivers d ON t.driver_id = d.id
WHERE t.user_id = ? AND t.created_at > ?
ORDER BY t.created_at DESC
LIMIT 20 OFFSET 0;
```

**Có 2 phương án giảm load trên RDS primary:**

## So sánh Phương án

### Option 1: Caching Only (Spring Cache + Redis)

**Implementation:**

```java
@Cacheable(value = "tripHistory", key = "#userId")
public List<Trip> getTripHistory(Long userId) {
    return tripRepository.findByUserId(userId);
}
```

**Pros:**

- Latency cực thấp: 10ms (cache hit)
- Cost thấp: Redis đã có sẵn cho driver-service (~$20/month)
- Dễ implement: Spring Cache annotation

**Cons:**

- Vô hiệu hóa cache phức tạp (khi trip status thay đổi)
- Khởi động lạnh: Cache miss → 800ms latency
- Limited by Redis RAM (cache.t3.micro = 512 MB)
- Nhất quán cuối cùng: TTL 10 phút → user thấy data cũ

### Option 2: Read Replica Only (RDS Read Replica)

**Implementation:**

```properties
spring.datasource.url=jdbc:postgresql://${TRIP_DB_ENDPOINT}/...  # Primary
spring.datasource.read-replica.url=jdbc:postgresql://${TRIP_DB_REPLICA_ENDPOINT}/...  # Replica
```

**Pros:**

- Nhất quán mạnh: Độ trễ sao chép < 1s (gần như real-time)
- Unlimited reads: Không giới hạn bởi RAM như cache
- Dùng cho analytics, reporting (không chỉ trip history)
- Độ khả dụng cao: Replica ở AZ khác

**Cons:**

- Latency cao hơn cache: 200ms (DB query)
- Cost cao: +$30/month (db.t3.micro replica)
- Complexity: Application phải route reads/writes đúng endpoint

### Option 3: Both - Defense in Depth (CHOSEN) ✅

**Implementation:**

```
┌─────────────┐
│   Request   │
└──────┬──────┘
       │
       v
┌─────────────────┐
│  Spring Cache   │  ← 90% cache hit (10ms)
│  (TTL 10 min)   │
└────┬────────┬───┘
     │        │
  Hit│        │Miss
     v        v
  Return  ┌──────────────┐
          │ Read Replica │  ← 10% cache miss (200ms)
          │  (trip_db)   │
          └──────────────┘
```

## Quyết định

Áp dụng **CẢ HAI** phương pháp (Layered Caching Strategy):

### Layer 1: Spring Cache (L1 Cache)

- **TTL**: 10 phút
- **Eviction**: On trip status change (COMPLETED, CANCELLED)
- **Hit Rate**: ~82% (dự kiến sau tuning)
- **Latency**: 10ms

### Layer 2: Read Replica (L2 Cache / Persistent Store)

- **Usage**: Cache miss, real-time reporting, analytics
- **Replication Lag**: < 1s
- **Latency**: 200ms

### Layer 3: Primary DB (Write Only)

- **Usage**: INSERT, UPDATE, DELETE trips
- **Load Reduction**: 95% (chỉ handle writes + 5% cache misses)

### Read Replica Configuration

```hcl
resource "aws_db_instance" "trip_db_replica" {
  identifier          = "uit-go-trip-db-replica"
  replicate_source_db = aws_db_instance.trip_db.identifier
  instance_class      = "db.t3.micro"
  availability_zone   = "ap-southeast-1b"  # HA: Khác AZ với primary
  vpc_security_group_ids = [trip_db_sg.id]  # Same security group
}
```

## Lý do (Ưu tiên)

### 1. Defense in Depth - 2 Tiers of Protection (Ưu tiên cao nhất)

**Scenario 1: Cache hit (90%)**

- Request → Spring Cache → Return (10ms)
- Primary DB: 0% load
- Replica DB: 0% load

**Scenario 2: Cache miss (10%)**

- Request → Spring Cache miss → Read Replica → Cache & Return (200ms)
- Primary DB: 0% load (write traffic only)
- Replica DB: 10% read load

**Scenario 3: Cache + Replica failure (worst case)**

- Request → Spring Cache miss → Replica down → Failover to Primary (800ms)
- Giảm chất lượng nhẹ nhàng (không crash)

### 2. Performance - Kết hợp Ưu điểm Cả hai

| Request Type        | Latency  | Served By    |
| ------------------- | -------- | ------------ |
| Cache hit (90%)     | 10ms     | Spring Cache |
| Cache miss (9%)     | 200ms    | Read Replica |
| Replica down (1%)   | 800ms    | Primary DB   |
| **Average Latency** | **37ms** | **Mixed**    |

**vs Caching Only:**

- Cache miss → 800ms (query primary under load)
- Average: ~90ms

**vs Replica Only:**

- All reads → 200ms
- Average: 200ms

### 3. Flexibility - Multi-use Replica

**Use Cases:**

1. Trip history (user-facing, cached)
2. Admin dashboard (real-time, no cache)
3. Analytics queries (long-running, không ảnh hưởng primary)
4. Reporting (batch, overnight)

### 4. High Availability - Khả năng Phục hồi Xuyên AZ

- Primary: ap-southeast-1a
- Replica: ap-southeast-1b
- Nếu AZ-a fail → Replica có thể promote lên primary (failover)

## Đánh đổi (Chấp nhận)

### 1. Cost - $50/month vs $20 (Caching Only) - Tăng 150% (Acceptable)

**Breakdown:**

- Redis (existing): $20/month (cache.t3.micro)
- Read Replica: +$30/month (db.t3.micro)
- **Total**: $50/month

**Justification:**

- Performance gain: 37ms avg latency (vs 90ms với cache only)
- Availability: Cross-AZ HA
- Flexibility: Analytics, reporting capabilities
- **ROI**: $30/tháng = $1/ngày cho trải nghiệm người dùng tốt hơn + độ khả dụng cao

### 2. Complexity - 2 Systems to Manage (Acceptable)

**Quản lý Cache:**

- Invalidation logic: `@CacheEvict` khi trip status change
- TTL tuning: 10 phút là optimal? Hay 5 phút?
- Monitoring: Cache hit rate, eviction count

**Quản lý Replica:**

- Giám sát độ trễ sao chép
- Quy trình failover
- Định tuyến kết nối (primary vs replica endpoints)

**Mitigation:**

- Terraform IaC: Replica provisioning automated
- CloudWatch Alarms: `ReplicationLag > 5s` → alert
- Spring Boot profiles: Chuyển đổi dễ dàng giữa primary và replica

### 3. Eventual Consistency - Cache TTL 10 phút (Acceptable)

**Scenario:**

1. User completes trip → Status UPDATE to `COMPLETED`
2. Cache eviction → Cache cleared
3. User queries trip history → Cache miss → Query replica (lag < 1s) → Cache result
4. **User experience**: Thấy trip COMPLETED sau < 2s (acceptable)

**Alternative scenario (nếu không evict cache):**

1. User completes trip → Status UPDATE
2. User queries → Cache hit (stale data, status still `IN_PROGRESS`)
3. **User experience**: Thấy trip COMPLETED sau 10 phút (❌ unacceptable)

**Decision**: Vô hiệu hóa cache khi ghi để giảm lag xuống < 2s

### 4. Replication Lag - Typical < 1s, max 5s (Acceptable)

**Monitoring:**

```sql
-- Query trên replica để check lag
SELECT now() - pg_last_xact_replay_timestamp() AS replication_lag;
```

**SLA:**

- **Normal**: < 1s lag (99% time)
- **Peak**: < 5s lag (1% thời gian, khi primary có tăng đột biến ghi)
- **Alert**: > 10s lag (investigate primary load)

## Kết quả (Design Targets - To Be Validated)

### Primary DB Load Reduction (Expected)

| Metric                    | Before | After | Reduction |
| ------------------------- | ------ | ----- | --------- |
| Read Queries              | 900/s  | 45/s  | **95%**   |
| Write Queries             | 100/s  | 100/s | 0%        |
| CPU Utilization           | 75%    | 25%   | **67%**   |
| Database Connections Used | 45     | 15    | **67%**   |

### Cache Performance

| Metric          | Value |
| --------------- | ----- |
| Cache Hit Rate  | 82%   |
| Cache Miss Rate | 18%   |
| Avg Latency     | 37ms  |
| P95 Latency     | 120ms |

### Cost Breakdown

| Component    | Cost/Month | Justification                |
| ------------ | ---------- | ---------------------------- |
| Primary DB   | $30        | Existing (db.t3.micro)       |
| Read Replica | $30        | New (db.t3.micro, same size) |
| Redis        | $20        | Existing (cache.t3.micro)    |
| **Total**    | **$80**    | vs $30 baseline (2.7x)       |

**Đánh đổi chấp nhận**: 2.7x cost cho 10x performance improvement + HA

## Cấu hình Ứng dụng (Application-Level Configuration)

### Spring Boot Properties

```properties
# Primary DB (writes)
spring.datasource.primary.url=jdbc:postgresql://${TRIP_DB_ENDPOINT}/uit_trip_db
spring.datasource.primary.username=pgadmin
spring.datasource.primary.password=${TRIP_DB_PASSWORD}

# Read Replica (reads)
spring.datasource.replica.url=jdbc:postgresql://${TRIP_DB_REPLICA_ENDPOINT}/uit_trip_db
spring.datasource.replica.username=pgadmin
spring.datasource.replica.password=${TRIP_DB_PASSWORD}

# Cache config
spring.cache.type=redis
spring.cache.redis.time-to-live=600000  # 10 minutes
```

### Repository Layer

```java
@Repository
public class TripRepository {

    @Transactional  // Write to primary
    public Trip createTrip(Trip trip) {
        return entityManager.persist(trip);
    }

    @Transactional(readOnly = true)  // Read from replica
    @Cacheable(value = "tripHistory", key = "#userId")
    public List<Trip> getTripHistory(Long userId) {
        // Spring automatically routes to replica datasource
        return entityManager.createQuery("...", Trip.class).getResultList();
    }

    @CacheEvict(value = "tripHistory", key = "#trip.userId")
    public void updateTripStatus(Trip trip, Status newStatus) {
        trip.setStatus(newStatus);
        entityManager.merge(trip);  // Write to primary + evict cache
    }
}
```

## Tài liệu tham khảo

- [AWS RDS Read Replicas](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html)
- [Spring Cache Abstraction](https://docs.spring.io/spring-framework/docs/current/reference/html/integration.html#cache)
- [PostgreSQL Replication Lag Monitoring](https://www.postgresql.org/docs/current/monitoring-stats.html)
- Martin Fowler: [Cache-Aside Pattern](https://martinfowler.com/bliki/TwoHardThings.html)

## Validation Strategy

**Terraform Validation:**

```bash
cd terraform/modules/database
terraform plan | grep "trip_db_replica"
# Verify: Read replica configuration valid
```

**Chiến lược Kiểm thử Cục bộ:**

### Docker Compose Simulation:

```yaml
services:
  trip-db-primary:
    image: postgres:15
    # Write endpoint

  trip-db-replica:
    image: postgres:15
    # Simulate read replica (manual replication for testing)

  redis-cache:
    image: redis:7-alpine
```

### Testing Scenarios:

1. **Cache Performance Test:**

   - First request: Cache miss → Query replica → Measure latency
   - Second request: Cache hit → Measure latency improvement
   - Expected: 10ms (cache) vs 200ms (DB query)

2. **Read Replica Test:**

   - Direct query to primary vs replica
   - Measure load distribution
   - Verify: Replica can handle read-only queries

3. **Defense-in-Depth Test:**
   - Simulate cache failure (stop Redis)
   - Verify: System falls back to read replica gracefully
   - Simulate replica failure
   - Verify: System falls back to primary (degraded but functional)

### Success Criteria:

- Spring Cache integration working (cache hit/miss observable)
- Application can route reads to separate endpoint (read replica simulation)
- Failover logic validated (cache → replica → primary)
- Load testing shows latency improvement with caching
