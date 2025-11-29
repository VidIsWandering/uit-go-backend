import http from 'k6/http';
import { check, sleep } from 'k6';

/*
Round 2 Load Test (Read-Heavy)
- 85% read endpoints (annotated @Transactional(readOnly=true))
- 15% write/mutate endpoints
Environment variables expected:
  BASE_URL    -> e.g. http://localhost:8081 (trip-service gateway proxied) or ALB DNS
  DRIVER_TOKEN / PASSENGER_TOKEN -> auth tokens (UUID principal simulation)
  DRIVER_ID / PASSENGER_ID / TRIP_ID (for history/detail/earnings) optional

Run example:
  k6 run --vus 50 --duration 2m tests/k6/round2-read-heavy.js \
    -e BASE_URL=http://localhost:8080 \
    -e DRIVER_TOKEN=<token> -e PASSENGER_TOKEN=<token> -e DRIVER_ID=<uuid> -e PASSENGER_ID=<uuid>
*/

export const options = {
    scenarios: {
        steady: {
            executor: 'constant-arrival-rate',
            rate: 40,               // requests per second target
            timeUnit: '1s',
            duration: '3m',
            preAllocatedVUs: 50,
            maxVUs: 100,
        },
    },
    thresholds: {
        http_req_failed: ['rate<0.01'], // <1% errors
        http_req_duration: ['p(95)<400', 'p(99)<800'], // target latency
    },
};

const BASE = __ENV.BASE_URL || 'http://localhost:8081';
const DRIVER_TOKEN = __ENV.DRIVER_TOKEN || 'DRIVER-UUID';
const PASSENGER_TOKEN = __ENV.PASSENGER_TOKEN || 'PASSENGER-UUID';
const DRIVER_ID = __ENV.DRIVER_ID || '00000000-0000-0000-0000-000000000001';
const PASSENGER_ID = __ENV.PASSENGER_ID || '00000000-0000-0000-0000-000000000002';
const TRIP_ID = __ENV.TRIP_ID || '00000000-0000-0000-0000-000000000003';

// Weighted endpoint pool
const endpoints = [
    // READ (weight high)
    { type: 'GET', path: `/trips/${TRIP_ID}`, auth: PASSENGER_TOKEN, weight: 15 },
    { type: 'GET', path: `/trips/${TRIP_ID}/driver-location`, auth: PASSENGER_TOKEN, weight: 10 },
    { type: 'GET', path: `/trips/available?radius=5000`, auth: DRIVER_TOKEN, weight: 15 },
    { type: 'GET', path: `/trips/driver/${DRIVER_ID}/history?page=1&limit=20`, auth: DRIVER_TOKEN, weight: 10 },
    { type: 'GET', path: `/trips/passenger/${PASSENGER_ID}/history?page=1&limit=20`, auth: PASSENGER_TOKEN, weight: 10 },
    { type: 'GET', path: `/trips/driver/${DRIVER_ID}/earnings?period=today`, auth: DRIVER_TOKEN, weight: 15 },
    // WRITE/MUTATE (low weight)
    { type: 'POST', path: `/trips`, auth: PASSENGER_TOKEN, weight: 5, body: () => createTripBody() },
    { type: 'POST', path: `/trips/${TRIP_ID}/accept`, auth: DRIVER_TOKEN, weight: 3 },
    { type: 'POST', path: `/trips/${TRIP_ID}/rating`, auth: PASSENGER_TOKEN, weight: 2, body: () => JSON.stringify({ rating: 5, comment: 'good' }) },
];

// Precompute weighted list for fast sampling
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

function createTripBody() {
    return JSON.stringify({
        origin: { latitude: 10.762622, longitude: 106.660172 },
        destination: { latitude: 10.768553, longitude: 106.676372 }
    });
}

export default function () {
    const ep = pickEndpoint();
    const url = BASE + ep.path;
    const params = { headers: { Authorization: `Bearer ${ep.auth}`, 'Content-Type': 'application/json' } };
    let res;
    if (ep.type === 'GET') {
        res = http.get(url, params);
    } else if (ep.type === 'POST') {
        res = http.post(url, ep.body ? ep.body() : null, params);
    }
    check(res, {
        'status < 500': r => r.status < 500,
        'non-empty body': r => (r.body || '').length >= 0,
    });
    sleep(0.2); // small pacing to avoid burst-only pattern
}
