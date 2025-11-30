import http from 'k6/http';
import { check, sleep } from 'k6';

/*
Functional Business Logic Test
════════════════════════════════════════════════════════
Mục tiêu: Kiểm tra đầy đủ business logic flows
- Test cả READ và WRITE operations
- Low concurrency để tránh conflicts
- Focus vào correctness, không phải performance

Kịch bản:
- VUs: 3 (rất thấp để tránh race conditions)
- Duration: 5 phút
- Mỗi iteration test full workflow: create → get → accept → rating

Environment variables:
  BASE_URL         -> http://localhost:8081
  DRIVER_TOKEN     -> JWT token cho driver
  PASSENGER_TOKEN  -> JWT token cho passenger
  DRIVER_ID        -> UUID của driver test
  PASSENGER_ID     -> UUID của passenger test

Chạy test:
  Get-Content tests/k6/functional-business-logic.js | docker run --rm -i --network host `
    -e BASE_URL=http://localhost:8081 `
    -e DRIVER_TOKEN=<token> `
    -e PASSENGER_TOKEN=<token> `
    grafana/k6:latest run --out influxdb=http://localhost:8086/k6 -
*/

export const options = {
    scenarios: {
        functional_flow: {
            executor: 'constant-vus',
            vus: 3,              // Chỉ 3 VUs để minimize conflicts
            duration: '5m',
        },
    },
    thresholds: {
        http_req_failed: ['rate<0.3'],       // Cho phép 30% errors (business logic rejections)
        http_req_duration: ['p(95)<1000'],   // P95 < 1s
        checks: ['rate>0.85'],               // 85% checks pass
    },
};

const BASE = __ENV.BASE_URL || 'http://localhost:8081';
const DRIVER_TOKEN = __ENV.DRIVER_TOKEN || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDEiLCJpYXQiOjE3NjQ0NDUwNjYsImV4cCI6MTc2NDUzMTQ2Nn0.LEkjzXMTW0FZJ5mQaeRev-9Nsqzyx3dAgDl67yoVgf0';
const PASSENGER_TOKEN = __ENV.PASSENGER_TOKEN || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDIiLCJpYXQiOjE3NjQ0NDUwNjYsImV4cCI6MTc2NDUzMTQ2Nn0.YWSKNvT-cdoD26fMBPGKelXL7brGcy1yrLk4SmfXpo4';
const DRIVER_ID = __ENV.DRIVER_ID || '00000000-0000-0000-0000-000000000001';
const PASSENGER_ID = __ENV.PASSENGER_ID || '00000000-0000-0000-000000000002';

function createTripPayload() {
    return JSON.stringify({
        origin: {
            latitude: 10.762622,
            longitude: 106.660172
        },
        destination: {
            latitude: 10.768553,
            longitude: 106.676372
        }
    });
}

export default function () {
    // ═══════════════════════════════════════════════════════
    // STEP 1: Create Trip (WRITE)
    // ═══════════════════════════════════════════════════════
    const createRes = http.post(
        `${BASE}/trips`,
        createTripPayload(),
        {
            headers: {
                Authorization: `Bearer ${PASSENGER_TOKEN}`,
                'Content-Type': 'application/json'
            },
            tags: { name: 'Create Trip' }
        }
    );

    const createSuccess = check(createRes, {
        'create: status 201': r => r.status === 201,
        'create: has trip id': r => {
            try {
                const body = JSON.parse(r.body);
                return body && body.id;
            } catch {
                return false;
            }
        }
    });

    if (!createSuccess || createRes.status !== 201) {
        console.warn(`Failed to create trip: ${createRes.status}`);
        sleep(2);
        return;
    }

    const trip = JSON.parse(createRes.body);
    const tripId = trip.id;

    sleep(0.5); // Wait for DB persistence

    // ═══════════════════════════════════════════════════════
    // STEP 2: Get Trip Details (READ)
    // ═══════════════════════════════════════════════════════
    const getRes = http.get(
        `${BASE}/trips/${tripId}`,
        {
            headers: { Authorization: `Bearer ${PASSENGER_TOKEN}` },
            tags: { name: 'Get Trip' }
        }
    );

    check(getRes, {
        'get: status 200': r => r.status === 200,
        'get: correct id': r => {
            try {
                const body = JSON.parse(r.body);
                return body.id === tripId;
            } catch {
                return false;
            }
        }
    });

    sleep(0.3);

    // ═══════════════════════════════════════════════════════
    // STEP 3: Get Driver Location (READ - may fail if no driver)
    // ═══════════════════════════════════════════════════════
    http.get(
        `${BASE}/trips/${tripId}/driver-location`,
        {
            headers: { Authorization: `Bearer ${PASSENGER_TOKEN}` },
            tags: { name: 'Driver Location' }
        }
    );

    sleep(0.3);

    // ═══════════════════════════════════════════════════════
    // STEP 4: Get Available Trips (READ)
    // ═══════════════════════════════════════════════════════
    const availRes = http.get(
        `${BASE}/trips/available?radius=5000`,
        {
            headers: { Authorization: `Bearer ${DRIVER_TOKEN}` },
            tags: { name: 'Available Trips' }
        }
    );

    check(availRes, {
        'available: status 200': r => r.status === 200,
        'available: has array': r => {
            try {
                const body = JSON.parse(r.body);
                return Array.isArray(body);
            } catch {
                return false;
            }
        }
    });

    sleep(0.5);

    // ═══════════════════════════════════════════════════════
    // STEP 5: Accept Trip (WRITE - may fail due to business rules)
    // ═══════════════════════════════════════════════════════
    const acceptRes = http.post(
        `${BASE}/trips/${tripId}/accept`,
        null,
        {
            headers: { Authorization: `Bearer ${DRIVER_TOKEN}` },
            tags: { name: 'Accept Trip' }
        }
    );

    check(acceptRes, {
        'accept: not 500': r => r.status < 500,
    });

    sleep(0.5);

    // ═══════════════════════════════════════════════════════
    // STEP 6: Get Driver History (READ)
    // ═══════════════════════════════════════════════════════
    const driverHistRes = http.get(
        `${BASE}/trips/driver/${DRIVER_ID}/history?page=1&limit=20`,
        {
            headers: { Authorization: `Bearer ${DRIVER_TOKEN}` },
            tags: { name: 'Driver History' }
        }
    );

    check(driverHistRes, {
        'driver history: status 200': r => r.status === 200,
    });

    sleep(0.3);

    // ═══════════════════════════════════════════════════════
    // STEP 7: Get Passenger History (READ)
    // ═══════════════════════════════════════════════════════
    http.get(
        `${BASE}/trips/passenger/${PASSENGER_ID}/history?page=1&limit=20`,
        {
            headers: { Authorization: `Bearer ${PASSENGER_TOKEN}` },
            tags: { name: 'Passenger History' }
        }
    );

    sleep(0.3);

    // ═══════════════════════════════════════════════════════
    // STEP 8: Get Driver Earnings (READ)
    // ═══════════════════════════════════════════════════════
    http.get(
        `${BASE}/trips/driver/${DRIVER_ID}/earnings?period=today`,
        {
            headers: { Authorization: `Bearer ${DRIVER_TOKEN}` },
            tags: { name: 'Driver Earnings' }
        }
    );

    sleep(1); // Long delay between full workflows to reduce conflicts
}
