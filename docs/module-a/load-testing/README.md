# Load Testing - Module A

## 📋 Overview

Load testing cho Module A sử dụng **k6** để đo performance trước và sau optimizations.

**Testing Environment**: Local Docker Compose  
**Tool**: [k6](https://k6.io/)  
**Metrics**: Request rate, latency (p95/p99), error rate, CPU/Memory

---

## 🎯 Test Scenarios

### 1. Baseline (01-baseline.js)

**Purpose**: Warm-up và validate system health  
**Load Profile**: 10 → 50 VUs over 2 minutes  
**Endpoints**: User registration, login  
**Success Criteria**: p95 < 300ms, 0% errors

### 2. Create Trip Flow (02-create-trip.js)

**Purpose**: Test core business flow  
**Load Profile**: 20 → 100 VUs over 3 minutes  
**Endpoints**: Find driver → Create trip  
**Success Criteria**: p95 < 500ms, < 1% errors

### 3. Driver Location Updates (03-driver-updates.js)

**Purpose**: Test write-heavy workload  
**Load Profile**: 50 constant VUs for 5 minutes  
**Endpoints**: PATCH /drivers/{id}/location  
**Success Criteria**: p95 < 200ms, throughput > 200 RPS

### 4. Trip History Queries (04-trip-history.js)

**Purpose**: Test read-heavy workload + cache effectiveness  
**Load Profile**: 30 → 150 VUs over 3 minutes  
**Endpoints**: GET /trips/passenger/{id}/history  
**Success Criteria**: p95 < 100ms (after caching), cache hit > 80%

---

## 🚀 Running Tests

### Prerequisites

```bash
# Install k6
brew install k6  # macOS
# OR
sudo apt install k6  # Ubuntu

# Start local stack
cd /home/baonq/projects/uit-go-backend
docker compose up -d
```

### Execute Single Scenario

```bash
cd docs/module-a/load-testing/scenarios
k6 run 01-baseline.js
```

### Execute with Environment Variables

```bash
BASE_URL=http://localhost:8080 k6 run 02-create-trip.js
```

### Export Results to JSON

```bash
k6 run --out json=../results/before-optimization/baseline-results.json 01-baseline.js
```

---

## 📊 Collecting Metrics

### Grafana Dashboards

1. Open: http://localhost:3000
2. Navigate to: Dashboards → UIT-Go Metrics
3. Take screenshots during test execution:
   - Request rate panel
   - Response time (p95/p99) panel
   - CPU/Memory usage panel

### Save Screenshots

- **Before Optimization**: `results/before-optimization/`
- **After Optimization**: `results/after-optimization/`

**Naming Convention**: `{scenario}-{metric}-{timestamp}.png`  
Example: `create-trip-latency-before.png`

---

## 📁 Folder Structure

```
load-testing/
├── README.md                           # This file
├── scenarios/
│   ├── 01-baseline.js                  # User registration/login
│   ├── 02-create-trip.js               # Core flow test
│   ├── 03-driver-updates.js            # Write-heavy test
│   └── 04-trip-history.js              # Read-heavy test
└── results/
    ├── before-optimization/
    │   ├── README.md                   # Analysis report
    │   └── *.png                       # Grafana screenshots
    └── after-optimization/
        ├── README.md                   # Comparison report
        └── *.png                       # Grafana screenshots
```

---

## 🎯 Expected Improvements

| Metric         | Before  | After (Target) | Improvement   |
| -------------- | ------- | -------------- | ------------- |
| Throughput     | 100 RPS | 500+ RPS       | 5x            |
| Latency p95    | 500ms   | < 200ms        | 60% reduction |
| Cache Hit Rate | 0%      | > 80%          | N/A           |
| Error Rate     | < 1%    | < 0.1%         | 10x better    |

---

## 📝 Reporting

### Before Optimization Report

Create `results/before-optimization/README.md` with:

1. Test execution summary (date, duration, VUs)
2. Key metrics table
3. Bottleneck analysis (e.g., "DB queries slow, no connection pooling")
4. Screenshots

### After Optimization Report

Create `results/after-optimization/README.md` with:

1. Same structure as before
2. **Side-by-side comparison** với before metrics
3. Root cause → Solution mapping (e.g., "Added Spring Cache → 80% cache hit")
4. Screenshots

---

**Owner**: Role A (Nguyễn Việt Khoa)  
**Timeline**: Week 11-12
