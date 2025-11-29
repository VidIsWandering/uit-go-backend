import http from 'k6/http';
import { check, sleep } from 'k6';

/*
READ-ONLY Performance Test - Pure Performance Baseline
════════════════════════════════════════════════════════
Mục tiêu: Đo lường hiệu năng THỰC SỰ của hệ thống
- 100% READ endpoints (không có WRITE operations)
- Không có business logic conflicts
- Strict thresholds để đảm bảo error rate < 0.1%

Kịch bản:
- Duration: 3 phút
- Rate: 50 RPS (requests per second)
- VUs: 50-100

Environment variables:
  BASE_URL         -> http://localhost:8081
  DRIVER_TOKEN     -> JWT token cho driver
  PASSENGER_TOKEN  -> JWT token cho passenger
  DRIVER_ID        -> UUID của driver test
  PASSENGER_ID     -> UUID của passenger test

Chạy test:
  Get-Content tests/k6/read-only-performance.js | docker run --rm -i --network host `
    -e BASE_URL=http://localhost:8081 `
    -e DRIVER_TOKEN=<token> `
    -e PASSENGER_TOKEN=<token> `
    grafana/k6:latest run --out influxdb=http://localhost:8086/k6 -
*/

export const options = {
    scenarios: {
        read_only_performance: {
            executor: 'constant-arrival-rate',
            rate: 50,               // 50 requests/second
            timeUnit: '1s',
            duration: '3m',
            preAllocatedVUs: 50,
            maxVUs: 100,
        },
    },
    thresholds: {
        http_req_failed: ['rate<0.001'],     // < 0.1% errors (very strict)
        http_req_duration: ['p(95)<100'],    // P95 < 100ms
        http_req_duration: ['p(99)<200'],    // P99 < 200ms
        checks: ['rate>0.999'],              // 99.9% checks pass
    },
};

const BASE = __ENV.BASE_URL || 'http://localhost:8081';
const DRIVER_TOKEN = __ENV.DRIVER_TOKEN || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDEiLCJpYXQiOjE3NjQ0NDUwNjYsImV4cCI6MTc2NDUzMTQ2Nn0.LEkjzXMTW0FZJ5mQaeRev-9Nsqzyx3dAgDl67yoVgf0';
const PASSENGER_TOKEN = __ENV.PASSENGER_TOKEN || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDIiLCJpYXQiOjE3NjQ0NDUwNjYsImV4cCI6MTc2NDUzMTQ2Nn0.YWSKNvT-cdoD26fMBPGKelXL7brGcy1yrLk4SmfXpo4';
const DRIVER_ID = __ENV.DRIVER_ID || '00000000-0000-0000-0000-000000000001';
const PASSENGER_ID = __ENV.PASSENGER_ID || '00000000-0000-0000-0000-000000000002';

// 100% READ endpoints - Tất cả có @Transactional(readOnly=true)
const endpoints = [
    {
        name: 'Available Trips',
        type: 'GET',
        path: `/trips/available?radius=5000`,
        auth: DRIVER_TOKEN,
        weight: 25
    },
    {
        name: 'Driver History',
        type: 'GET',
        path: `/trips/driver/${DRIVER_ID}/history?page=1&limit=20`,
        auth: DRIVER_TOKEN,
        weight: 25
    },
    {
        name: 'Passenger History',
        type: 'GET',
        path: `/trips/passenger/${PASSENGER_ID}/history?page=1&limit=20`,
        auth: PASSENGER_TOKEN,
        weight: 25
    },
    {
        name: 'Driver Earnings',
        type: 'GET',
        path: `/trips/driver/${DRIVER_ID}/earnings?period=today`,
        auth: DRIVER_TOKEN,
        weight: 25
    },
];

// Build weighted pool for random selection
const weightedPool = buildWeightedPool(endpoints);

function buildWeightedPool(list) {
    const arr = [];
    list.forEach(e => {
        for (let i = 0; i < e.weight; i++) arr.push(e);
    });
    return arr;
}

function pickEndpoint() {
    const idx = Math.floor(Math.random() * weightedPool.length);
    return weightedPool[idx];
}

export default function () {
    const ep = pickEndpoint();
    const url = BASE + ep.path;
    const params = {
        headers: {
            Authorization: `Bearer ${ep.auth}`,
            'Content-Type': 'application/json'
        },
        tags: { name: ep.name }  // Tag for better metrics grouping
    };

    const res = http.get(url, params);

    check(res, {
        'status is 200': r => r.status === 200,
        'response has body': r => r.body && r.body.length > 0,
        'response time < 500ms': r => r.timings.duration < 500,
    });

    sleep(0.2);  // Prevent burst patterns
}
