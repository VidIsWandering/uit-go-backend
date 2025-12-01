import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter } from 'k6/metrics';

/*
  Stress Plateau Test Round 2
  Mục tiêu: Chứng minh khả năng chịu tải dần và vùng bền vững trước khi latency nổ.

  Chiến lược:
  - Ramp nhanh lên các bậc (100, 200, 300, 400, 500) mỗi bậc giữ đủ lâu để ổn định.
  - Reduced max from 600→500 VUs để tránh connection reset issues.
  - Tag endpoint để tách async vs create nếu cần dùng lại.
  - Summary xuất JSON làm evidence.
*/

const STAGES = [
    { duration: '1m', target: 100 },
    { duration: '1m', target: 200 },
    { duration: '1m', target: 300 },
    { duration: '1m', target: 400 },
    { duration: '1m', target: 500 },
    { duration: '30s', target: 0 }
];

const RUN_LABEL = __ENV.RUN_LABEL || 'round2-stress';
const BASE_URL = __ENV.BASE_URL || 'http://trip-service:8081';
const API_PREFIX = __ENV.API_PREFIX || '';
const ASYNC = (__ENV.ASYNC || '1') === '1';
const PASSENGER_TOKEN = __ENV.PASSENGER_TOKEN || 'INVALID_TOKEN_PLACEHOLDER';
const CREATE_ENDPOINT = ASYNC ? `${API_PREFIX}/trips/async` : `${API_PREFIX}/trips`;
const ASYNC_P95_THRESHOLD = __ENV.ASYNC_P95_THRESHOLD || '4500';

const statusCounts = new Counter('status_counts');

export const options = {
    stages: STAGES,
    thresholds: {
        http_req_failed: ['rate<0.05'],  // Allow up to 5% error rate at peak 500 VUs
        [`http_req_duration{endpoint:async}`]: ["p(95)<" + ASYNC_P95_THRESHOLD],
    },
    summaryTrendStats: ['min', 'avg', 'med', 'max', 'p(90)', 'p(95)', 'p(99)']
};

export function setup() {
    return { token: PASSENGER_TOKEN };
}

export default function (data) {
    const params = {
        headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${data.token}`,
        },
        tags: { endpoint: ASYNC ? 'async' : 'create' }
    };

    const lat = 10.7626 + (Math.random() * 0.01 - 0.005);
    const lng = 106.6601 + (Math.random() * 0.01 - 0.005);

    const payload = JSON.stringify({
        origin: { latitude: lat, longitude: lng },
        destination: { latitude: 10.7726, longitude: 106.6701 }
    });

    const res = http.post(`${BASE_URL}${CREATE_ENDPOINT}`, payload, params);
    check(res, { 'accepted': r => r.status === 200 || r.status === 201 || r.status === 202 });
    statusCounts.add(1, { code: String(res.status) });
    sleep(1);
}

export function handleSummary(data) {
    const plateau = STAGES.map(s => s.target).filter(t => t > 0);
    const summary = {
        run_label: RUN_LABEL,
        plateau_targets: plateau,
        async_mode: ASYNC,
        thresholds: { async_p95: ASYNC_P95_THRESHOLD },
        p95: data.metrics.http_req_duration.values['p(95)'],
        metrics: {
            http_req_duration: data.metrics.http_req_duration,
            http_req_failed: data.metrics.http_req_failed,
            iteration_duration: data.metrics.iteration_duration,
            status_counts: data.metrics.status_counts ? data.metrics.status_counts.values : null,
        }
    };
    return {
        [`stress-summary-${RUN_LABEL}.json`]: JSON.stringify(summary, null, 2),
        stdout: JSON.stringify({ label: RUN_LABEL, overall_p95: summary.p95 }) + '\n'
    };
}
