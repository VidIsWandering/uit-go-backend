# Role A (Nguyễn Việt Khoa) - Module A Tasks Checklist

## 👤 Your Responsibilities

- **Focus**: Code-level optimization (Java services)
- **Focus**: Load testing & performance measurement
- **Deliverables**: 4 ADRs, load testing scripts & results, optimized code

---

## ⚠️ AWS Strategy Note

**Current Plan (Phase 1)**: Load testing on **Local Docker Compose**

- **Reason**: AWS Free Tier constraints (ALB limit, cost concerns)
- **Validation**: Relative improvements (before/after) are valid proof
- **Cost**: $0

**Future Option (Phase 2)**: If instructor requires AWS testing

- Deploy to AWS for 1 day (~$5-8)
- Run quick load tests
- Destroy immediately
- **Status**: ⏳ Pending instructor confirmation

**Action**: ✅ Proceed with local testing now. Files are designed to easily switch to AWS if needed.

---

## 📅 Week 9-10: Code Optimization

### ✅ Task A.1: Implement Spring Cache cho TripService

**Deadline**: End of Week 9

**What to do**:

1. Add Spring Cache dependency to `trip-service/pom.xml`:

   ```xml
   <dependency>
       <groupId>org.springframework.boot</groupId>
       <artifactId>spring-boot-starter-cache</artifactId>
   </dependency>
   <dependency>
       <groupId>org.springframework.boot</groupId>
       <artifactId>spring-boot-starter-data-redis</artifactId>
   </dependency>
   ```

2. Enable caching in `TripServiceApplication.java`:

   ```java
   @EnableCaching
   public class TripServiceApplication { ... }
   ```

3. Add cache config in `application.properties`:

   ```properties
   spring.cache.type=redis
   spring.cache.redis.time-to-live=600000
   spring.redis.host=${REDIS_CACHE_HOST:localhost}
   spring.redis.port=${REDIS_CACHE_PORT:6379}
   ```

4. Add `@Cacheable` to methods in `TripService.java`:

   ```java
   @Cacheable(value = "tripHistory", key = "#passengerId + '-' + #page")
   public Page<Trip> getPassengerHistory(UUID passengerId, int page, int limit) {
       // existing code
   }

   @Cacheable(value = "driverHistory", key = "#driverId + '-' + #page")
   public Page<Trip> getDriverHistory(UUID driverId, int page, int limit) {
       // existing code
   }
   ```

5. Add `@CacheEvict` when trip status changes:
   ```java
   @CacheEvict(value = {"tripHistory", "driverHistory"}, allEntries = true)
   public Trip completeTrip(UUID tripId, UUID driverId) {
       // existing code
   }
   ```

**Testing**:

- Start Redis container: `docker run -d -p 6379:6379 redis:7-alpine`
- Run trip-service and call `/trips/passenger/{id}/history` twice
- Second call should be faster (cache hit)

**Files to modify**:

- `trip-service/pom.xml`
- `trip-service/src/main/java/.../TripServiceApplication.java`
- `trip-service/src/main/java/.../service/TripService.java`
- `trip-service/src/main/resources/application.properties`

**Dependencies**: None (can work independently)

---

### ✅ Task A.2: Thêm Resilience4j Circuit Breaker

**Deadline**: End of Week 9

**What to do**:

1. Add Resilience4j dependency to `trip-service/pom.xml`:

   ```xml
   <dependency>
       <groupId>io.github.resilience4j</groupId>
       <artifactId>resilience4j-spring-boot2</artifactId>
       <version>2.1.0</version>
   </dependency>
   ```

2. Add config in `application.properties`:

   ```properties
   resilience4j.circuitbreaker.instances.driverService.slidingWindowSize=10
   resilience4j.circuitbreaker.instances.driverService.failureRateThreshold=50
   resilience4j.circuitbreaker.instances.driverService.waitDurationInOpenState=10000
   resilience4j.circuitbreaker.instances.driverService.permittedNumberOfCallsInHalfOpenState=3

   resilience4j.retry.instances.driverService.maxAttempts=3
   resilience4j.retry.instances.driverService.waitDuration=500
   ```

3. Modify `DriverService.java`:

   ```java
   import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
   import io.github.resilience4j.retry.annotation.Retry;

   @CircuitBreaker(name = "driverService", fallbackMethod = "getDefaultLocation")
   @Retry(name = "driverService")
   public LocationDTO getDriverLocation(UUID driverId) {
       // existing RestTemplate call
   }

   // Fallback method
   private LocationDTO getDefaultLocation(UUID driverId, Exception e) {
       // Return default TP.HCM location when driver-service is down
       return new LocationDTO(10.8231, 106.6297);
   }
   ```

**Testing**:

- Stop driver-service container
- Call `/trips/{id}/driver-location`
- Should return default location instead of error

**Files to modify**:

- `trip-service/pom.xml`
- `trip-service/src/main/java/.../service/DriverService.java`
- `trip-service/src/main/resources/application.properties`

**Dependencies**: None

---

### ✅ Task A.3: Tối ưu HikariCP Connection Pool

**Deadline**: End of Week 9

**What to do**:

1. Calculate optimal pool size:

   - Formula: `pool_size = (core_count * 2) + disk_count`
   - ECS Fargate 0.25 vCPU → recommended: 2-3 connections/task
   - If scale to 10 tasks → 20-30 total connections (RDS t3.micro max: 87)

2. Add to `user-service/src/main/resources/application.properties`:

   ```properties
   spring.datasource.hikari.maximum-pool-size=5
   spring.datasource.hikari.minimum-idle=2
   spring.datasource.hikari.connection-timeout=30000
   spring.datasource.hikari.idle-timeout=600000
   spring.datasource.hikari.max-lifetime=1800000
   spring.datasource.hikari.leak-detection-threshold=60000
   ```

3. Add to `trip-service/src/main/resources/application.properties`:

   ```properties
   # Same config as above
   spring.datasource.hikari.maximum-pool-size=5
   spring.datasource.hikari.minimum-idle=2
   ...
   ```

4. Add metrics exposure:
   ```properties
   management.metrics.enable.hikari=true
   ```

**Testing**:

- Check logs for HikariCP initialization
- Access `/actuator/metrics/hikari.connections.active`
- Should see connection pool metrics

**Files to modify**:

- `user-service/src/main/resources/application.properties`
- `trip-service/src/main/resources/application.properties`

**Dependencies**: None

---

### ✅ Task A.4: Tối ưu RestTemplate HTTP Client

**Deadline**: End of Week 10

**What to do**:

1. Add Apache HttpClient dependency to `trip-service/pom.xml`:

   ```xml
   <dependency>
       <groupId>org.apache.httpcomponents</groupId>
       <artifactId>httpclient</artifactId>
   </dependency>
   ```

2. Modify `RestTemplateConfig.java`:

   ```java
   import org.apache.http.impl.client.HttpClients;
   import org.apache.http.impl.conn.PoolingHttpClientConnectionManager;
   import org.springframework.http.client.HttpComponentsClientHttpRequestFactory;

   @Bean
   public RestTemplate restTemplate() {
       // Create connection pool
       PoolingHttpClientConnectionManager cm = new PoolingHttpClientConnectionManager();
       cm.setMaxTotal(100);           // Max total connections
       cm.setDefaultMaxPerRoute(20);  // Max per host

       // Create HTTP client with pool
       HttpClient httpClient = HttpClients.custom()
           .setConnectionManager(cm)
           .build();

       // Create factory with timeouts
       HttpComponentsClientHttpRequestFactory factory =
           new HttpComponentsClientHttpRequestFactory(httpClient);
       factory.setConnectTimeout(2000);  // 2s
       factory.setReadTimeout(5000);     // 5s

       RestTemplate rt = new RestTemplate(factory);

       // Keep existing logging interceptor
       rt.getInterceptors().add(...);

       return rt;
   }
   ```

**Testing**:

- Restart trip-service
- Call endpoints that use RestTemplate
- Check logs for connection reuse

**Files to modify**:

- `trip-service/pom.xml`
- `trip-service/src/main/java/.../config/RestTemplateConfig.java`

**Dependencies**: None

---

## 📅 Week 11: Load Testing

### ✅ Task A.5: Viết k6 Load Testing Scripts

**Deadline**: Mid Week 11

**What to do**:

1. Install k6:

   ```bash
   # Ubuntu/WSL
   sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
   echo "deb https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
   sudo apt-get update
   sudo apt-get install k6
   ```

2. Create folder structure:

   ```bash
   mkdir -p load-testing/scripts
   mkdir -p load-testing/results
   ```

3. Create `load-testing/scripts/scenario-1-baseline.js`:

   ```javascript
   import http from "k6/http";
   import { check, sleep } from "k6";

   export const options = {
     stages: [
       { duration: "1m", target: 50 }, // Ramp up to 50 users
       { duration: "3m", target: 50 }, // Stay at 50 users
       { duration: "1m", target: 0 }, // Ramp down
     ],
   };

   export default function () {
     // Register user
     const registerPayload = JSON.stringify({
       email: `user${__VU}@test.com`,
       password: "testpass123",
       fullName: "Test User",
       phone: "0909123456",
       role: "PASSENGER",
     });

     const registerRes = http.post(
       "http://localhost:8080/users",
       registerPayload,
       {
         headers: { "Content-Type": "application/json" },
       }
     );

     check(registerRes, {
       "register status is 201": (r) => r.status === 201,
     });

     sleep(1);

     // Login
     const loginPayload = JSON.stringify({
       email: `user${__VU}@test.com`,
       password: "testpass123",
     });

     const loginRes = http.post(
       "http://localhost:8080/sessions",
       loginPayload,
       {
         headers: { "Content-Type": "application/json" },
       }
     );

     check(loginRes, {
       "login status is 200": (r) => r.status === 200,
     });

     sleep(1);
   }
   ```

4. Create similar scripts for scenarios 2-4 (see detailed examples in MODULE_A_PLAN.md)

**Testing**:

```bash
# Run scenario 1
k6 run load-testing/scripts/scenario-1-baseline.js

# Should see output with metrics: http_reqs, http_req_duration, etc.
```

**Files to create**:

- `load-testing/scripts/scenario-1-baseline.js`
- `load-testing/scripts/scenario-2-create-trip.js`
- `load-testing/scripts/scenario-3-driver-updates.js`
- `load-testing/scripts/scenario-4-trip-history.js`

**Dependencies**: Need local Docker Compose running

---

### ✅ Task A.6: Thực thi Load Tests (Before Optimization)

**Deadline**: End of Week 11

**What to do**:

1. Ensure all services running:

   ```bash
   docker compose up -d
   ```

2. Run each scenario và ghi nhận kết quả:

   ```bash
   k6 run --out json=results/scenario-1-before.json load-testing/scripts/scenario-1-baseline.js
   k6 run --out json=results/scenario-2-before.json load-testing/scripts/scenario-2-create-trip.js
   k6 run --out json=results/scenario-3-before.json load-testing/scripts/scenario-3-driver-updates.js
   k6 run --out json=results/scenario-4-before.json load-testing/scripts/scenario-4-trip-history.js
   ```

3. Take screenshots of Grafana dashboards:

   - Open http://localhost:3001
   - Navigate to UIT-Go dashboard
   - Screenshot: HTTP request rate, latency p95/p99, CPU/Memory

4. Create report `load-testing/results/before-optimization.md`:

   ```markdown
   # Load Testing Results - Before Optimization

   ## Test Environment

   - Date: YYYY-MM-DD
   - Infrastructure: **Local Docker Compose**
   - Hardware: [Your laptop specs, e.g., "8 vCPU, 16GB RAM"]
   - Services: user-service, trip-service, driver-service

   ## Environment Note

   Testing performed on local Docker Compose due to AWS Free Tier constraints.
   While absolute metrics differ from production AWS, **relative improvements**
   (before vs after optimization) remain valid for demonstrating effectiveness.

   ## Scenario 1: Baseline (Register + Login)

   - Virtual Users: 50
   - Duration: 5 minutes
   - Results:
     - Total Requests: XXXX
     - Requests/sec: XX.XX
     - Latency p95: XXXms
     - Latency p99: XXXms
     - Error Rate: X.XX%

   ## Scenario 2: Create Trip

   ...

   ## Bottlenecks Identified

   1. TripService /trips/passenger/{id}/history: 800ms p95 (no cache)
   2. DriverService calls timeout when >100 concurrent requests
   3. Database connection pool exhausted at 200 RPS

   ## Screenshots

   ![Grafana Before](../screenshots/grafana-before-1.png)
   ```

**Files to create**:

- `load-testing/results/before-optimization.md`
- `load-testing/screenshots/` (folder with images)

**Dependencies**:

- ✅ Can work independently (local environment)
- ⚠️ Coordinate with Role B if need to switch to AWS later

---

**🔄 Migration Path to AWS** (if instructor requires):

1. Update k6 scripts: Change `http://localhost:8080` → `http://<ALB_DNS>`
2. Role B deploys AWS infrastructure (1 day)
3. Re-run same scenarios on AWS
4. Compare local vs AWS results in report

---

## 📅 Week 12: Re-test & Documentation

### ✅ Task A.7: Thực thi Load Tests (After Optimization) - LOCAL

**Deadline**: Mid Week 12

**CURRENT APPROACH**: Testing on **Local Docker Compose** (same as Task A.6)

**What to do**:

1. ✅ Ensure all optimizations deployed locally:

   - Spring Cache enabled
   - Circuit Breaker configured
   - HikariCP tuned
   - RestTemplate pooling active

2. Restart services to pick up changes:

   ```bash
   docker compose down
   docker compose up -d --build
   ```

3. Run same scenarios again:

   ```bash
   k6 run --out json=results/scenario-1-after.json load-testing/scripts/scenario-1-baseline.js
   k6 run --out json=results/scenario-2-after.json load-testing/scripts/scenario-2-create-trip.js
   k6 run --out json=results/scenario-3-after.json load-testing/scripts/scenario-3-driver-updates.js
   k6 run --out json=results/scenario-4-after.json load-testing/scripts/scenario-4-trip-history.js
   ```

4. Create comparison report `load-testing/results/after-optimization.md`:

   ```markdown
   # Load Testing Results - After Optimization

   ## Improvements Summary

   | Metric                     | Before | After | Improvement |
   | -------------------------- | ------ | ----- | ----------- |
   | RPS (Scenario 2)           | 100    | 450   | +350%       |
   | Latency p95 (Trip History) | 800ms  | 120ms | -85%        |
   | Cache Hit Rate             | 0%     | 82%   | N/A         |
   | Auto-scale Response Time   | N/A    | 90s   | N/A         |

   ## Key Findings

   1. Spring Cache reduced trip history latency by 85%
   2. Circuit Breaker prevented cascading failures
   3. Auto-scaling handled 5x load increase
      ...
   ```

**Files to create**:

- `load-testing/results/after-optimization.md`
- `load-testing/results/comparison-charts.md`

**Dependencies**:

- ⚠️ Coordinate with Role B to ensure Terraform code is validated (Task B.8)
- ✅ Can proceed with local testing without AWS deployment

---

**🔄 Migration Path to AWS** (if instructor requires):

- Re-run tests on AWS after Role B deploys (1 day)
- Compare local vs AWS results
- Update report with production metrics

---

### ✅ Task A.8: Viết ADR cho Code Optimization

**Deadline**: End of Week 12

**What to do**:
Create 4 ADR files in `docs/adr/`:

**1. `013-spring-cache-strategy.md`:**

```markdown
# ADR 013: Spring Cache Strategy cho Trip History

## Trạng thái

Được chấp nhận (Accepted) - Module A

## Bối cảnh

Trip history là read-heavy workload (1 write : 100 reads). Mỗi query vào DB tốn ~500ms. Khi scale, DB sẽ là bottleneck.

## Quyết định

Sử dụng Spring Cache với Redis backend, TTL 10 phút, cache invalidation khi trip status thay đổi.

## Lý do (Ưu tiên)

- **Performance**: Giảm 85% latency (800ms → 120ms)
- **Scalability**: Giảm 90% load trên RDS primary
- **Cost**: Redis ElastiCache t3.micro rẻ hơn scale RDS

## Đánh đổi (Chấp nhận)

- **Consistency**: Có thể thấy data cũ trong 10 phút (eventual consistency)
- **Complexity**: Phải quản lý cache invalidation logic
- **Memory**: Redis cần ~2GB RAM cho 100K trips cached

## Kết quả

Load testing cho thấy cache hit rate 82%, latency p95 giảm từ 800ms → 120ms.
```

**2. `014-circuit-breaker-pattern.md`:**

```markdown
# ADR 014: Circuit Breaker Pattern cho Driver Service Calls

## Trạng thái

Được chấp nhận (Accepted) - Module A

## Bối cảnh

TripService gọi DriverService qua REST (synchronous). Khi DriverService chậm/down, TripService bị timeout cascade, waste threads.

## Quyết định

Implement Resilience4j Circuit Breaker với:

- Failure threshold: 50% (trong 10 requests)
- Open state duration: 10s
- Fallback: return default TP.HCM location

## Lý do (Ưu tiên)

- **Reliability**: Prevent cascading failures
- **User Experience**: Fallback better than error
- **Resource**: Release threads faster

## Đánh đổi (Chấp nhận)

- **Accuracy**: Fallback location không chính xác
- **Complexity**: Thêm config và monitoring

## Kết quả

Khi simulate DriverService down, TripService vẫn phản hồi trong 200ms thay vì timeout 30s.
```

**3. `015-connection-pool-sizing.md`** (similar structure)

**4. `016-http-client-pooling.md`** (similar structure)

**Files to create**:

- `docs/adr/013-spring-cache-strategy.md`
- `docs/adr/014-circuit-breaker-pattern.md`
- `docs/adr/015-connection-pool-sizing.md`
- `docs/adr/016-http-client-pooling.md`

**Dependencies**: None

---

### ✅ Task A.9: Chuẩn bị Demo + Presentation

**Deadline**: End of Week 12

**What to do**:

1. Create demo script:

   ```markdown
   # Live Demo Script - Module A (Role A)

   ## Part 1: Show Cache in Action (2 mins)

   1. Call `/trips/passenger/{id}/history` → show 800ms latency
   2. Call again → show 120ms latency (cache hit)
   3. Complete a trip → show cache invalidated
   4. Call history again → slow (cache miss), then fast

   ## Part 2: Circuit Breaker Demo (2 mins)

   1. Call `/trips/{id}/driver-location` → normal response
   2. Stop driver-service container
   3. Call again → show fallback location (no error)
   4. Show Resilience4j metrics dashboard

   ## Part 3: Load Testing Results (3 mins)

   1. Show k6 output before optimization
   2. Show k6 output after optimization
   3. Highlight improvements table
   4. Show Grafana dashboards comparison
   ```

2. Prepare slides (PowerPoint/Google Slides):
   - Slide 1: Code Optimization Overview
   - Slide 2: Spring Cache Architecture
   - Slide 3: Circuit Breaker Flow
   - Slide 4: Load Testing Methodology
   - Slide 5-6: Before/After Comparison Charts
   - Slide 7: Lessons Learned

**Files to create**:

- `docs/presentation/role-a-demo-script.md`
- `docs/presentation/role-a-slides.pptx`

**Dependencies**: None

---

## ✅ Final Checklist

Before handing off to Role B for final integration:

- [ ] All code changes committed to Git (branch: `module-a/role-a-optimization`)
- [ ] All 4 ADRs reviewed and finalized
- [ ] Load testing results documented with screenshots
- [ ] Demo script tested and working
- [ ] Presentation slides ready
- [ ] Code reviewed by teammate (optional but recommended)

---

## 🆘 Troubleshooting & FAQs

**Q: Redis connection refused khi test Spring Cache?**
A: Đảm bảo Redis container đang chạy: `docker ps | grep redis`

**Q: Circuit breaker không trigger?**
A: Check config: `resilience4j.circuitbreaker.instances.driverService.failureRateThreshold=50` (50% failure)

**Q: k6 báo lỗi "connection refused"?**
A: Services chưa chạy. Run: `docker compose up -d`

**Q: Load test làm crash services?**
A: Giảm virtual users xuống 20, tăng dần để tìm breaking point.

**Q: Cần thêm Redis instance cho cache?**
A: Có thể dùng chung Redis với driver-service (local) hoặc yêu cầu Role B tạo ElastiCache riêng (AWS).

---

## 📞 Contact Points

**Need help from Role B (Bảo)?**

- Terraform issues (infrastructure)
- AWS deployment questions
- Security group / network issues

**You can help Role B with:**

- Java code review
- Application-level metrics explanation
- Load testing insights

---

**Good luck! 🚀**
