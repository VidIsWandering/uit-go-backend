# Phân tích Các Đánh đổi Kiến trúc (Trade-off Analysis)

## Giới thiệu

Tài liệu này phân tích chi tiết các quyết định kiến trúc quan trọng trong hệ thống UIT-Go, giải thích **tại sao chọn giải pháp A thay vì B**, và **đánh đổi** (trade-off) của mỗi lựa chọn.

---

## 1. ASYNC COMMUNICATION vs SYNC COMMUNICATION

### Bối cảnh vấn đề

Khi khách hàng đặt xe, TripService cần thông báo cho DriverService để tìm tài xế. Có 2 cách:

**Cách 1: Synchronous (Đồng bộ)**
```
Client → TripService → gọi trực tiếp DriverService → trả kết quả
```

**Cách 2: Asynchronous (Bất đồng bộ - SQS)**
```
Client → TripService → đẩy message vào Queue → trả "Đã nhận"
                       ↓
                  DriverService tự đọc Queue và xử lý
```

### Quyết định: Chọn ASYNC (SQS)

### Trade-offs chi tiết

| Tiêu chí | Synchronous | Asynchronous (SQS) | Lựa chọn |
|----------|-------------|---------------------|----------|
| **Latency** | ⚡ Nhanh (~200ms) | 🐌 Chậm hơn (~2-5s) | ❌ Mất |
| **Reliability** | ⚠️ Sập khi DriverService lỗi | ✅ Luôn nhận request | ✅ Được |
| **Scalability** | ⚠️ Giới hạn bởi DriverService | ✅ Vô hạn (Queue buffer) | ✅ Được |
| **Complexity** | ✅ Đơn giản (1 HTTP call) | ⚠️ Phức tạp (Queue, Consumer, DLQ) | ❌ Mất |
| **Cost** | ✅ Free | 💰 SQS ~$0.40/1M requests | ❌ Mất |
| **User Experience** | ✅ Biết ngay có xe | ⚠️ Phải đợi/polling | ❌ Mất |

### Giải thích chi tiết

#### Được gì?

1. **Chống Flash Crowd (tăng đột biến):**
   ```
   Scenario: Mưa to, 10,000 người cùng đặt xe trong 1 phút.
   
   Sync: DriverService bị 10,000 request → CPU 100% → timeout → sập.
   Async: 10,000 message vào Queue → DriverService xử lý từ từ 100 msg/s → không sập.
   ```

2. **Decoupling (tách rời):**
   - TripService không cần biết DriverService còn sống không.
   - Có thể upgrade/restart DriverService mà không ảnh hưởng TripService.

3. **Infinite Buffer:**
   - Queue có thể chứa hàng triệu message, không giới hạn như RAM của server.

#### Mất gì?

1. **Latency cao hơn:**
   ```
   Sync: Client biết ngay "Có tài xế A" sau 200ms.
   Async: Client nhận "Đã nhận yêu cầu", phải đợi 2-5s để biết kết quả.
   ```

2. **Complexity tăng:**
   - Phải xử lý: Message format, retry logic, DLQ, idempotency.
   - Debugging khó hơn (message đi qua nhiều hệ thống).

3. **Eventual Consistency:**
   - Dữ liệu không nhất quán ngay lập tức.
   - VD: Trip status = "FINDING_DRIVER" trong DB, nhưng driver đã nhận (message chưa process xong).

### Kết luận lựa chọn

**Chọn ASYNC** vì:
- Độ tin cậy (Reliability) quan trọng hơn độ nhanh (Latency) với ứng dụng gọi xe.
- Tránh sập hệ thống trong giờ cao điểm là ưu tiên #1.
- Khách hàng chấp nhận đợi vài giây (đã quen với Grab, Uber).

**Đánh đổi chấp nhận được:**
- Latency tăng ~2s: OK (so với sập hệ thống).
- Complexity: Đáng giá để đạt hyper-scale.

---

## 2. READ REPLICAS vs SINGLE DATABASE

### Bối cảnh vấn đề

Hệ thống có ~90% request là đọc dữ liệu (GET: lịch sử trip, thông tin user). Database chính (Primary) bị quá tải.

**Cách 1: Single Database**
```
Mọi request (đọc + ghi) → Primary DB
```

**Cách 2: Read Replicas**
```
Request đọc → Read Replica 1, 2, 3
Request ghi → Primary DB → sync sang Replicas
```

### Quyết định: Chọn READ REPLICAS

### Trade-offs chi tiết

| Tiêu chí | Single DB | Read Replicas | Lựa chọn |
|----------|-----------|---------------|----------|
| **Read Throughput** | ⚠️ Giới hạn (~500 rps) | ✅ Gấp 3-5 lần | ✅ Được |
| **Cost** | ✅ $20/tháng | 💰 $80/tháng (1 primary + 3 replicas) | ❌ Mất |
| **Consistency** | ✅ Luôn mới nhất | ⚠️ Có thể đọc dữ liệu cũ (lag ~1s) | ❌ Mất |
| **Complexity** | ✅ Đơn giản | ⚠️ Phải code routing logic | ❌ Mất |
| **Availability** | ⚠️ Sập = toàn bộ sập | ✅ Replica failover | ✅ Được |

### Giải thích chi tiết

#### Được gì?

1. **Tăng throughput đọc:**
   ```
   Trước: 1 DB chịu 100% traffic → CPU 90%, latency 500ms.
   Sau: Primary 10% (ghi) + 3 Replicas mỗi cái 30% (đọc) → CPU 40%, latency 100ms.
   
   Kết quả: Hệ thống chịu được 3x lượng request.
   ```

2. **High Availability:**
   - Nếu Primary sập, promote 1 Replica lên làm Primary mới.
   - Downtime chỉ ~30s (thay vì vài giờ phải restore backup).

3. **Geo-distribution (nâng cao):**
   - Đặt Replica gần user (Singapore, Tokyo) → giảm latency.

#### Mất gì?

1. **Replication Lag (độ trễ đồng bộ):**
   ```
   Scenario: User cập nhật ảnh đại diện.
   
   t=0s: POST /users/123 (ghi vào Primary) → "Thành công"
   t=0.5s: Dữ liệu đồng bộ từ Primary → Replica (lag)
   t=1s: GET /users/123 (đọc từ Replica) → vẫn thấy ảnh cũ!
   
   → User thấy "ảnh chưa đổi" → UX tệ.
   ```

   **Giải pháp:**
   - Với dữ liệu quan trọng (sau khi payment), đọc từ Primary trong 5s.
   - Với dữ liệu ít quan trọng (vị trí tài xế), chấp nhận lag.

2. **Cost gấp 4 lần:**
   - 1 Primary + 3 Replicas = 4 instances.
   - Chi phí tăng tuyến tính.

3. **Code complexity:**
   ```java
   // Phải code logic chọn DB
   @Transactional(readOnly = true)  // → Replica
   public Trip getTrip(...) {}
   
   @Transactional  // → Primary
   public Trip updateTrip(...) {}
   ```

### Kết luận lựa chọn

**Chọn READ REPLICAS** vì:
- Hệ thống read-heavy (90% đọc) → đòn bẩy lớn.
- Performance cải thiện 3x đáng giá với chi phí.
- Replication lag ~1s chấp nhận được với dữ liệu geo (vị trí tài xế).

**Đánh đổi chấp nhận được:**
- Cost tăng: Đổi lại được 3x capacity → ROI tốt.
- Eventual consistency: Xử lý bằng cache aside pattern.

---

## 3. REDIS CACHE vs NO CACHE

### Bối cảnh vấn đề

User profile (tên, avatar, email) được truy vấn **mỗi request** (để xác thực), nhưng ít khi thay đổi.

**Cách 1: Không cache**
```
Mỗi request → Query DB → trả dữ liệu
→ DB phải xử lý 1000 query giống nhau/giây
```

**Cách 2: Redis Cache**
```
Request → Check Redis → Nếu có, trả ngay (cache hit)
                      → Nếu không, query DB + lưu vào Redis (cache miss)
```

### Quyết định: Chọn REDIS CACHE

### Trade-offs chi tiết

| Tiêu chí | No Cache | Redis Cache | Lựa chọn |
|----------|----------|-------------|----------|
| **Latency** | 🐌 50-100ms (DB query) | ⚡ 1-2ms (RAM) | ✅ Được |
| **DB Load** | 💥 100% traffic hit DB | ✅ Chỉ 10-20% (miss) | ✅ Được |
| **Cost** | ✅ $0 | 💰 $15/tháng (Redis) | ❌ Mất |
| **Consistency** | ✅ Luôn mới nhất | ⚠️ Có thể cũ nếu không evict | ❌ Mất |
| **Complexity** | ✅ Đơn giản | ⚠️ Cache invalidation logic | ❌ Mất |

### Giải thích chi tiết

#### Được gì?

1. **Latency giảm 50x:**
   ```
   Trước: Mỗi request query DB → 50ms
   Sau: Đọc từ Redis RAM → 1ms
   
   → API response time giảm từ 200ms → 150ms
   ```

2. **Giảm tải DB:**
   ```
   Cache hit rate 80% → DB chỉ phải xử lý 20% traffic thật.
   
   VD: 1000 req/s → chỉ 200 req/s hit DB → CPU DB giảm từ 90% → 30%
   ```

3. **Giá rẻ hơn scale DB:**
   ```
   Để chịu 1000 rps:
   - Không cache: Cần DB instance lớn (db.m5.large ~$150/tháng)
   - Có cache: DB nhỏ (db.t3.micro ~$20) + Redis ($15) = $35/tháng
   
   → Tiết kiệm $115/tháng!
   ```

#### Mất gì?

1. **Cache Invalidation - "Bài toán khó nhất trong CS":**
   ```
   Scenario: User đổi tên từ "Minh" → "Khoa"
   
   Nếu quên xóa cache:
   t=0s: UPDATE users SET name='Khoa' → DB updated
   t=1s: GET /users/123 → Redis trả "Minh" (cache cũ) ❌
   
   → Dữ liệu sai!
   ```

   **Giải pháp:**
   ```java
   @CacheEvict(value = "users", key = "#user.id")
   public User updateUser(User user) {
       // Xóa cache trước khi update DB
   }
   ```

2. **Memory Eviction:**
   ```
   Redis RAM đầy → Xóa bớt cache theo LRU (Least Recently Used).
   → Cache hit rate giảm → DB load tăng đột ngột.
   
   Phải monitor: Redis memory usage, eviction count.
   ```

3. **Complexity:**
   - Phải code cache logic.
   - Debug khó hơn (dữ liệu ở 2 nơi: Redis + DB).

### Kết luận lựa chọn

**Chọn REDIS CACHE** vì:
- Latency cải thiện 50x → UX tốt hơn nhiều.
- Tiết kiệm chi phí scaling DB.
- User profile ít thay đổi → cache hit rate cao (~80%).

**Đánh đổi chấp nhận được:**
- Cost $15: Rẻ so với lợi ích.
- Complexity: Xử lý bằng Spring Cache abstraction (@Cacheable).

---

## 4. AUTO-SCALING vs FIXED CAPACITY

### Bối cảnh vấn đề

Lưu lượng người dùng thay đổi theo giờ:
- **6-9h sáng, 17-20h chiều:** Cao điểm (~500 rps)
- **0-6h đêm:** Thấp điểm (~50 rps)

**Cách 1: Fixed Capacity (cố định)**
```
Luôn chạy 10 servers (đủ cho cao điểm)
→ Lãng phí 90% tài nguyên vào ban đêm
```

**Cách 2: Auto-scaling**
```
Cao điểm: Tự động tăng lên 10 servers
Thấp điểm: Giảm xuống 2 servers
```

### Quyết định: Chọn AUTO-SCALING

### Trade-offs chi tiết

| Tiêu chí | Fixed 10 Servers | Auto-scaling 2-10 | Lựa chọn |
|----------|------------------|-------------------|----------|
| **Cost** | 💰 $400/tháng (24/7) | 💰 $150/tháng (avg) | ✅ Được |
| **Simplicity** | ✅ Đơn giản | ⚠️ Phức tạp (metric, threshold) | ❌ Mất |
| **Reliability** | ✅ Luôn sẵn sàng | ⚠️ Cold start delay (~1-2 phút) | ❌ Mất |
| **Elasticity** | ❌ Không linh hoạt | ✅ Tự động điều chỉnh | ✅ Được |

### Giải thích chi tiết

#### Được gì?

1. **Tiết kiệm chi phí 60%:**
   ```
   Fixed:
   10 servers * 24h * 30 days * $0.05/h = $360
   
   Auto-scaling:
   Cao điểm (8h/day): 10 servers * 8h * 30 days * $0.05 = $120
   Thấp điểm (16h/day): 2 servers * 16h * 30 days * $0.05 = $48
   Total: $168
   
   Tiết kiệm: $192/tháng (53%)
   ```

2. **Chống bất ngờ:**
   ```
   Event đặc biệt (concert, mưa bão) → traffic tăng gấp 3.
   
   Fixed 10 servers: Quá tải → sập.
   Auto-scaling: Tự động tăng lên 30 servers → OK.
   ```

3. **Xanh hơn (Green):**
   - Dùng ít tài nguyên = ít điện = thân thiện môi trường.

#### Mất gì?

1. **Cold Start Problem:**
   ```
   Scenario: Traffic tăng đột ngột 6h sáng.
   
   t=0s: CPU 70% → Trigger scale out
   t=60s: Container mới khởi động xong
   t=90s: Health check pass → Nhận traffic
   
   → 90s đầu, hệ thống vẫn quá tải!
   ```

   **Giải pháp:**
   - Đặt Min Capacity = 3 (luôn có sẵn).
   - Scale out sớm (threshold CPU 60% thay vì 80%).

2. **Flapping (dao động):**
   ```
   t=0: CPU 71% → Scale out → 10 servers
   t=5: CPU 69% → Scale in → 9 servers
   t=10: CPU 71% → Scale out → 10 servers
   ...
   
   → Servers bật tắt liên tục → không ổn định.
   ```

   **Giải pháp:**
   - Scale out nhanh (3 phút), scale in chậm (15 phút).
   - Dùng cooldown period.

3. **Complexity cao:**
   ```
   Phải config:
   - CloudWatch metrics
   - Target Tracking Policy
   - Min/Max/Desired capacity
   - Health checks
   - Deployment strategy (rolling update)
   
   → Khó debug khi lỗi.
   ```

### Kết luận lựa chọn

**Chọn AUTO-SCALING** vì:
- Tiết kiệm chi phí 50%+ → quan trọng với startup.
- Chống được traffic spike bất ngờ.
- Cloud-native best practice.

**Đánh đổi chấp nhận được:**
- Cold start 1-2 phút: Xử lý bằng cách đặt Min Capacity cao hơn.
- Complexity: Terraform abstraction giúp quản lý dễ hơn.

---

## 5. OPTIMISTIC LOCKING vs PESSIMISTIC LOCKING

### Bối cảnh vấn đề

2 tài xế cùng lúc bấm "Nhận chuyến" cho cùng 1 trip → Race condition.

**Cách 1: Pessimistic Locking (Bi quan)**
```sql
SELECT * FROM trips WHERE id = 123 FOR UPDATE;  -- Khóa dòng này
UPDATE trips SET driver_id = 456 WHERE id = 123;
COMMIT;  -- Mở khóa
```

**Cách 2: Optimistic Locking (Lạc quan)**
```sql
SELECT id, version FROM trips WHERE id = 123;  -- version = 5
UPDATE trips SET driver_id = 456, version = 6
WHERE id = 123 AND version = 5;  -- Chỉ update nếu version chưa đổi
→ Nếu version đã = 6 (ai đó update trước), UPDATE fail.
```

### Quyết định: Chọn OPTIMISTIC LOCKING

### Trade-offs chi tiết

| Tiêu chí | Pessimistic | Optimistic | Lựa chọn |
|----------|-------------|------------|----------|
| **Throughput** | ⚠️ Thấp (giữ lock lâu) | ✅ Cao (không lock) | ✅ Được |
| **Deadlock Risk** | 💥 Cao | ✅ Không có | ✅ Được |
| **Retry Logic** | ✅ Không cần | ⚠️ Phải retry nếu fail | ❌ Mất |
| **Consistency** | ✅ 100% | ✅ 100% (nếu retry đúng) | ✅ Bằng nhau |
| **Use Case Fit** | Phù hợp Write-Heavy | Phù hợp Read-Heavy | ✅ Được |

### Giải thích chi tiết

#### Được gì?

1. **Throughput cao hơn:**
   ```
   Pessimistic:
   - Driver 1 lock trip 123 → Driver 2 phải đợi
   - Driver 1 xử lý 500ms → Driver 2 mới được lock
   → Max 2 requests/giây

   Optimistic:
   - Driver 1 đọc trip → version = 5
   - Driver 2 đọc trip → version = 5 (đồng thời)
   - Driver 1 update (version 5 → 6) → Thành công
   - Driver 2 update (version 5 → 6) → Fail (version đã là 6)
   → Driver 2 retry ngay
   
   → Không block, throughput cao hơn 10x
   ```

2. **Không deadlock:**
   ```
   Pessimistic deadlock scenario:
   Transaction A: Lock trip 1 → đợi lock trip 2
   Transaction B: Lock trip 2 → đợi lock trip 1
   → Cả 2 đợi nhau mãi → Deadlock!
   
   Optimistic: Không lock → Không deadlock.
   ```

3. **Phù hợp read-heavy:**
   - Hệ thống UIT-Go: 90% đọc, 10% ghi.
   - Xung đột thực tế rất thấp (~1% trips).
   - Optimistic không ảnh hưởng 99% requests.

#### Mất gì?

1. **Phải xử lý retry:**
   ```java
   @Transactional
   public Trip acceptTrip(UUID tripId, UUID driverId) {
       try {
           trip.setDriverId(driverId);
           trip.setVersion(trip.getVersion() + 1);
           return tripRepo.save(trip);
       } catch (OptimisticLockException e) {
           // Có người khác nhận rồi
           throw new TripAlreadyAcceptedException();
       }
   }
   ```

2. **User experience khi conflict:**
   ```
   Driver A bấm nhận → Thành công
   Driver B bấm nhận 0.1s sau → Lỗi "Chuyến đã có người nhận"
   
   → Driver B thất vọng (nhưng đúng logic nghiệp vụ)
   ```

3. **Không phù hợp write-heavy:**
   - Nếu 90% requests là ghi, conflict rate cao → retry nhiều → hiệu năng tệ.

### Kết luận lựa chọn

**Chọn OPTIMISTIC LOCKING** vì:
- Hệ thống read-heavy → conflict rate thấp (~1%).
- Throughput cao hơn 10x so với Pessimistic.
- Tránh deadlock.

**Đánh đổi chấp nhận được:**
- Retry logic: Xử lý đơn giản với JPA `@Version`.
- Conflict UX: Đúng với nghiệp vụ (chỉ 1 driver nhận được trip).

---

## 6. TỔNG KẾT TRADE-OFFS

### Ma trận quyết định

| Quyết định | Được | Mất | Lý do chọn |
|------------|------|-----|------------|
| Async (SQS) | Reliability, Scalability | Latency, Complexity | Ưu tiên ổn định > nhanh |
| Read Replicas | Throughput 3x, HA | Cost 4x, Lag | Read-heavy → ROI cao |
| Redis Cache | Latency 50x, DB offload | Cost, Invalidation | User profile ít đổi |
| Auto-scaling | Cost -50%, Elastic | Cold start, Complexity | Startup cần tiết kiệm |
| Optimistic Lock | Throughput 10x, No deadlock | Retry logic | Read-heavy, conflict thấp |

### Nguyên tắc thiết kế

Qua 5 quyết định trên, ta thấy pattern chung:

**1. Ưu tiên Reliability > Speed:**
- Chấp nhận latency tăng 2s (async) để tránh sập hệ thống.

**2. Tối ưu cho Read-Heavy:**
- 90% traffic là đọc → Read Replica, Cache, Optimistic Lock.

**3. Cost-Performance Balance:**
- Chi $15 Redis để tiết kiệm $115 DB scaling.
- Chi complexity để được scalability.

**4. Cloud-Native First:**
- Auto-scaling, managed services (SQS, ElastiCache).
- Infrastructure as Code (Terraform).

**5. Eventual Consistency chấp nhận được:**
- Với ứng dụng gọi xe, lag 1-2s không ảnh hưởng UX nghiêm trọng.

---

## 7. METRICS ĐỂ KIỂM CHỨNG

Để chứng minh các trade-off đúng đắn, ta cần đo:

| Trade-off | Metric đo | Target |
|-----------|-----------|--------|
| Async latency | End-to-end time (POST /trips → Driver assigned) | < 5s |
| Replica throughput | Requests/second before error | 3x baseline |
| Cache effectiveness | Cache hit rate | > 70% |
| Auto-scaling cost | AWS bill / month | < 50% fixed capacity |
| Optimistic lock conflict | OptimisticLockException rate | < 1% |

**Kế hoạch:**
- Load Test Round 2 sẽ đo các metrics này.
- So sánh trước/sau optimization.
- Ghi vào `ROUND2-SUMMARY.md`.

---

**Tài liệu được tạo để phục vụ Module A - Trade-off Analysis.**  
**Ngày:** 29/11/2025
