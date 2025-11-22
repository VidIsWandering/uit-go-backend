# Role A: Backend Developer Tasks (Nguyễn Việt Khoa)

## 🎯 Your Focus

- Code-level optimization (Java Spring Boot)
- Load testing & performance measurement
- **Deliverables**: 4 ADRs, k6 scripts, test results, optimized code

---

## 📅 Week 9-10: Code Optimization

### Task A.1: Spring Cache cho TripService ⏱️ Week 9

**Goal**: Cache trip history để giảm DB queries

**Steps**:

1. Add dependencies vào `trip-service/pom.xml`:
   - `spring-boot-starter-cache`
   - `spring-boot-starter-data-redis`
2. Enable `@EnableCaching` trong `TripServiceApplication.java`
3. Config Redis trong `application.properties`:
   ```properties
   spring.cache.type=redis
   spring.cache.redis.time-to-live=600000
   spring.redis.host=${REDIS_CACHE_HOST:localhost}
   ```
4. Add annotations:
   - `@Cacheable` cho `getPassengerHistory()`, `getDriverHistory()`
   - `@CacheEvict` cho `completeTrip()`, `cancelTrip()`

**Acceptance Criteria**:

- [ ] Second call to `/trips/passenger/{id}/history` nhanh hơn lần đầu
- [ ] Cache invalidates khi trip status changes
- [ ] Works với local Redis container

**Files**: `pom.xml`, `TripServiceApplication.java`, `TripService.java`, `application.properties`

---

### Task A.2: Circuit Breaker cho DriverService Calls ⏱️ Week 9

**Goal**: Prevent cascading failures khi DriverService slow/down

**Steps**:

1. Add `resilience4j-spring-boot2` vào `trip-service/pom.xml`
2. Config trong `application.properties`:
   ```properties
   resilience4j.circuitbreaker.instances.driverService.slidingWindowSize=10
   resilience4j.circuitbreaker.instances.driverService.failureRateThreshold=50
   ```
3. Add `@CircuitBreaker(name = "driverService", fallbackMethod = "fallbackFindDriver")`
   trong `DriverServiceClient.java`
4. Implement fallback method return empty list hoặc cached drivers

**Acceptance Criteria**:

- [ ] Circuit opens sau 5/10 failed calls
- [ ] Fallback method returns graceful response
- [ ] Circuit auto-recovers sau timeout

**Files**: `pom.xml`, `DriverServiceClient.java`, `application.properties`

---

### Task A.3: HikariCP Connection Pool Tuning ⏱️ Week 10

**Goal**: Optimize DB connection usage cho high throughput

**Steps**:

1. Calculate optimal pool size: `connections = ((core_count × 2) + effective_spindle_count)`
2. Config cho `user-service/application.properties`:
   ```properties
   spring.datasource.hikari.maximum-pool-size=20
   spring.datasource.hikari.minimum-idle=5
   spring.datasource.hikari.connection-timeout=30000
   ```
3. Repeat cho `trip-service/application.properties`
4. Monitor pool usage via actuator: `/actuator/metrics/hikaricp.connections.active`

**Acceptance Criteria**:

- [ ] Pool size matches formula calculation
- [ ] No connection timeout errors under load
- [ ] Pool utilization < 80% during normal load

**Files**: `user-service/application.properties`, `trip-service/application.properties`

---

### Task A.4: RestTemplate HTTP Client Pooling ⏱️ Week 10

**Goal**: Reuse HTTP connections cho inter-service calls

**Steps**:

1. Create `RestTemplateConfig.java` trong `trip-service`
2. Configure Apache HttpClient với pooling:
   ```java
   @Bean
   public RestTemplate restTemplate() {
       HttpComponentsClientHttpRequestFactory factory =
           new HttpComponentsClientHttpRequestFactory();
       factory.setConnectionRequestTimeout(5000);
       factory.setConnectTimeout(5000);
       factory.setReadTimeout(10000);
       return new RestTemplate(factory);
   }
   ```
3. Inject `@Autowired RestTemplate` vào `DriverServiceClient.java`

**Acceptance Criteria**:

- [ ] HTTP connections reused (check via logs)
- [ ] Timeout configured properly
- [ ] Works với local DriverService

**Files**: `RestTemplateConfig.java` (new), `DriverServiceClient.java`

---

## 📅 Week 11: Load Testing Setup

### Task A.5: Viết k6 Load Testing Scripts ⏱️ Week 11

**Goal**: Create 4 scenarios để test bottlenecks

**Scenarios**:

1. **Baseline**: User registration + login (warm-up)
   - File: `docs/module-a/load-testing/scenarios/01-baseline.js`
   - VUs: 10 → 50 over 2 minutes
2. **Create Trip Flow**: Find driver + create trip (core flow)
   - File: `02-create-trip.js`
   - VUs: 20 → 100 over 3 minutes
3. **Driver Updates**: Location updates (write-heavy)
   - File: `03-driver-updates.js`
   - VUs: 50 constant for 5 minutes
4. **Trip History**: Query history (read-heavy, cache test)
   - File: `04-trip-history.js`
   - VUs: 30 → 150 over 3 minutes

**k6 Template**:

```javascript
import http from "k6/http";
import { check, sleep } from "k6";

export let options = {
  stages: [
    { duration: "1m", target: 50 },
    { duration: "2m", target: 50 },
    { duration: "1m", target: 0 },
  ],
  thresholds: {
    http_req_duration: ["p(95)<500"],
  },
};

export default function () {
  const BASE_URL = __ENV.BASE_URL || "http://localhost:8080";
  let res = http.get(`${BASE_URL}/users`);
  check(res, { "status 200": (r) => r.status === 200 });
  sleep(1);
}
```

**Acceptance Criteria**:

- [ ] All 4 scripts run successfully
- [ ] Metrics exported: http_req_duration, http_reqs
- [ ] Thresholds defined (p95 < 500ms)

**Files**: `docs/module-a/load-testing/scenarios/*.js`

---

### Task A.6: Load Tests BEFORE Optimization ⏱️ Week 11

**Goal**: Establish baseline metrics

**Steps**:

1. Start local stack: `docker compose up`
2. Run each k6 scenario:
   ```bash
   k6 run --out json=results.json 01-baseline.js
   ```
3. Capture Grafana screenshots (Prometheus datasource):
   - Request rate (RPS)
   - Response time p95/p99
   - CPU/Memory usage
4. Document bottlenecks trong `docs/module-a/load-testing/results/before-optimization/README.md`

**Acceptance Criteria**:

- [ ] All 4 scenarios executed
- [ ] Screenshots saved trong `before-optimization/`
- [ ] Bottleneck analysis documented (e.g., "DB queries slow, no caching")

**Deliverable**: Markdown report + PNG screenshots

---

## 📅 Week 12: Re-test & Documentation

### Task A.7: Load Tests AFTER Optimization ⏱️ Week 12

**Goal**: Measure improvements

**Steps**:

1. Deploy code với caching, circuit breaker, pool tuning
2. Re-run same 4 k6 scenarios
3. Capture Grafana screenshots
4. Compare before/after metrics trong `docs/module-a/load-testing/results/after-optimization/README.md`

**Acceptance Criteria**:

- [ ] Throughput improved ≥ 3x
- [ ] Latency p95 reduced ≥ 40%
- [ ] Cache hit rate > 70%
- [ ] Side-by-side comparison charts

**Deliverable**: Markdown report + PNG screenshots

---

### Task A.8: Viết 4 ADRs ⏱️ Week 12

**Goal**: Document code optimization decisions

**ADRs**:

1. **ADR-013**: Spring Cache Strategy
   - Context: Trip history queries hit DB every time
   - Decision: Redis cache với 10-min TTL
   - Trade-offs: Stale data vs Performance
2. **ADR-014**: Circuit Breaker Pattern
   - Context: DriverService calls can timeout
   - Decision: Resilience4j với fallback
   - Trade-offs: Complexity vs Resilience
3. **ADR-015**: Connection Pool Sizing
   - Context: Default HikariCP pool too small
   - Decision: 20 max connections based on formula
   - Trade-offs: Memory vs Throughput
4. **ADR-016**: HTTP Client Pooling
   - Context: RestTemplate creates new connection each call
   - Decision: Apache HttpClient với pooling
   - Trade-offs: Setup complexity vs Latency

**Template**: Use existing ADR format in `docs/adr/01x-module-a/`

**Acceptance Criteria**:

- [ ] All 4 ADRs complete với Context, Decision, Consequences
- [ ] Trade-offs clearly explained
- [ ] Linked from ARCHITECTURE.md

**Files**: `docs/adr/01x-module-a/013-*.md` through `016-*.md`

---

### Task A.9: Demo Preparation ⏱️ Week 12

**Goal**: Prepare live demo cho presentation

**Steps**:

1. Create demo script:
   - Show local stack running
   - Run 1 k6 scenario live
   - Show Grafana dashboard updating real-time
2. Prepare slides:
   - Before/After comparison charts
   - Code snippets (Spring Cache annotation)
   - Bottleneck analysis
3. Practice timing (5 phút max)

**Acceptance Criteria**:

- [ ] Demo runs smoothly end-to-end
- [ ] Backup screenshots if live demo fails
- [ ] Clear narrative: Problem → Solution → Results

---

## 🎯 Success Metrics

Your optimizations should achieve:

- **Throughput**: 100 RPS → 500+ RPS
- **Latency p95**: < 200ms
- **Cache Hit Rate**: > 80%
- **Zero errors** under normal load

---

## 📁 Your Deliverables Summary

| Item                   | Location                                                  | Status |
| ---------------------- | --------------------------------------------------------- | ------ |
| Spring Cache code      | `trip-service/`                                           | ⏳     |
| Circuit Breaker code   | `trip-service/`                                           | ⏳     |
| Connection pool config | `application.properties`                                  | ⏳     |
| HTTP client config     | `RestTemplateConfig.java`                                 | ⏳     |
| k6 scripts (4)         | `docs/module-a/load-testing/scenarios/`                   | ⏳     |
| Before test results    | `docs/module-a/load-testing/results/before-optimization/` | ⏳     |
| After test results     | `docs/module-a/load-testing/results/after-optimization/`  | ⏳     |
| ADRs 013-016           | `docs/adr/01x-module-a/`                                  | ⏳     |
| Demo materials         | Slides + script                                           | ⏳     |

---

**Dependencies**: Wait for Role B to complete B.1-B.4 before final testing  
**Sync Points**: End of Week 9, Week 10, Week 11, Week 12
