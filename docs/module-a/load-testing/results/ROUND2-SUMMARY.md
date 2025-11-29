# Round 2 Load Test - Read-Heavy Performance Summary

## Test Environment

- **Date**: [Ngày chạy test]
- **Test Script**: `tests/k6/round2-read-heavy.js`
- **k6 Version**: [k6 version]
- **Infrastructure Profile**: [Local / Hybrid / Full AWS]

## Test Configuration

- **Duration**: 5 minutes (300s)
- **Load Pattern**: Constant arrival rate - 100 req/s
- **Endpoint Distribution**:
  - ~85% GET (read-only endpoints)
  - ~15% POST/PUT (write operations)
- **Weighted Endpoints**:
  - `GET /trips/{id}` (detail)
  - `GET /trips/{id}/driver-location`
  - `GET /trips/available`
  - `GET /trips/passenger/{id}/history`
  - `GET /trips/driver/{id}/history`
  - `GET /trips/driver/{id}/earnings`
  - `POST /trips` (create)
  - `POST /trips/{id}/accept`
  - `POST /trips/{id}/complete`

## Infrastructure Setup

### Database Configuration
- **Primary DB**: postgres-trip (port 5432)
- **Read Replica**: postgres-trip-replica (port 5433)
- **Read/Write Routing**: Spring `RoutingDataSource` + `@Transactional(readOnly=true)`
- **Connection Pool (HikariCP)**:
  - `maximum-pool-size`: 20
  - `minimum-idle`: 10
  - `connection-timeout`: 250ms

### Caching Layer
- **trip-service**: Caffeine cache
  - `tripById`, `availableTrips`, `passengerHistory`, `driverHistory`, `driverEarnings`
  - TTL: 30s
  - Max size: 5000 entries
- **user-service**: Redis cache
  - `users` cache

### Query Logging
- **p6spy**: Enabled for SQL host validation (jdbc:p6spy:postgresql://)

## Test Results

### Performance Metrics

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| P95 Latency | [ms] | ≤ 500ms | [✓/✗] |
| P99 Latency | [ms] | ≤ 1000ms | [✓/✗] |
| Error Rate | [%] | ≤ 1% | [✓/✗] |
| Throughput | [req/s] | ≥ 95 req/s | [✓/✗] |
| HTTP Success Rate | [%] | ≥ 99% | [✓/✗] |

### Database Connection Distribution

**Primary vs Replica Split** (from p6spy logs or pg_stat_activity snapshot):

| Database | Connection Count | Query % | Notes |
|----------|------------------|---------|-------|
| postgres-trip (primary) | [count] | [%] | Write + fallback reads |
| postgres-trip-replica | [count] | [%] | Read-only transactions |

**Expected**: ~85% queries routed to replica; ~15% to primary.

**Actual**: [Kết quả thực tế]

### Cache Hit Metrics

**trip-service** (`GET /cache/stats`):

| Cache Name | Hits | Misses | Hit Rate | Evictions |
|------------|------|--------|----------|-----------|
| tripById | [count] | [count] | [%] | [count] |
| availableTrips | [count] | [count] | [%] | [count] |
| passengerHistory | [count] | [count] | [%] | [count] |
| driverHistory | [count] | [count] | [%] | [count] |
| driverEarnings | [count] | [count] | [%] | [count] |

**user-service** (`GET /cache/stats` + Prometheus `cache.gets`):

- Redis `users` cache: [hit rate / metrics from Prometheus]

### HikariCP Pool Metrics

**trip-service** (from `/actuator/prometheus`):

- `hikaricp.connections.active`: [avg/max]
- `hikaricp.connections.idle`: [avg]
- `hikaricp.connections.pending`: [avg/max]
- `hikaricp.connections.timeout.total`: [count]

**user-service**:

- [Tương tự metrics]

## Observations

### Đạt được
- [Các kết quả tích cực: latency giảm, read replica hoạt động, cache hit rate cao, etc.]

### Vấn đề phát hiện
- [Lỗi hoặc bottleneck: connection timeout, cache miss cao, replica không nhận traffic, etc.]

### Tuning Recommendations
1. [Gợi ý điều chỉnh: tăng pool size, tăng cache TTL, thêm index DB, etc.]
2. [...]

## Validation Checks

- [ ] Read-only endpoints correctly route to replica (verified via p6spy logs)
- [ ] Cache hit rate ≥ 70% for repeated reads
- [ ] No HikariCP connection timeouts
- [ ] P95 latency ≤ 500ms
- [ ] Error rate ≤ 1%

## Next Steps

- [Action items: apply tuning, re-run test, document final results, etc.]

## Raw Data

### k6 Summary Output
```
[Paste k6 text summary output here]
```

### Sample p6spy Log Excerpt
```
[Paste sample log showing jdbc:p6spy:postgresql://postgres-trip vs postgres-trip-replica]
```

### Prometheus Cache Metrics
```
[Paste relevant cache.gets, cache.puts, hikaricp.* metrics]
```

---

**Prepared by**: [Tên]  
**Last Updated**: [Ngày]
