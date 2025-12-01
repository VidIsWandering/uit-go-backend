import http from 'k6/http';
import { check, sleep } from 'k6';
import { Trend, Counter } from 'k6/metrics';

/*
  Read Replica Load Test
  Mục tiêu: Chứng minh việc phân tách đọc (estimate + GET trips) giảm áp lực write DB và cải thiện latency trung bình.
  Chiến lược: Tỷ lệ 70% request read (estimate + list) / 30% write (async create). Gắn tag để tách metric.
*/

const RUN_LABEL = __ENV.RUN_LABEL || 'round2-replica';
const BASE_URL = __ENV.BASE_URL || 'http://trip-service:8081';
const API_PREFIX = __ENV.API_PREFIX || '';
const PASSENGER_TOKEN = __ENV.PASSENGER_TOKEN || 'INVALID_TOKEN_PLACEHOLDER';
const TARGET_VUS = parseInt(__ENV.TARGET_VUS || '300');
const DURATION = __ENV.DURATION || '3m';

export const options = {
    vus: TARGET_VUS,
    duration: DURATION,
    thresholds: {
        'read_latency': ['p(95)<1500'],
        'write_latency': ['p(95)<2500']
    },
    summaryTrendStats: ['min', 'avg', 'med', 'max', 'p(90)', 'p(95)', 'p(99)']
};

const readLatency = new Trend('read_latency');
const writeLatency = new Trend('write_latency');
const readCount = new Counter('read_requests');
const writeCount = new Counter('write_requests');

export function setup() { return { token: PASSENGER_TOKEN }; }

export default function (data) {
    const headers = { 'Content-Type': 'application/json', Authorization: `Bearer ${data.token}` };
    const payload = JSON.stringify({ origin: { latitude: 10.7626, longitude: 106.6601 }, destination: { latitude: 10.7726, longitude: 106.6701 } });

    // Decide read vs write
    if (Math.random() < 0.7) { // read path
        // 50% estimate, 50% list (giả lập list trips - cần endpoint thực tế nếu có)
        if (Math.random() < 0.5) {
            const r = http.post(`${BASE_URL}${API_PREFIX}/trips/estimate`, payload, { headers, tags: { endpoint: 'estimate' } });
            check(r, { 'estimate ok': x => [200, 201, 202].includes(x.status) });
            readLatency.add(r.timings.duration);
        } else {
            const r = http.get(`${BASE_URL}${API_PREFIX}/trips?limit=5`, { headers, tags: { endpoint: 'list' } });
            check(r, { 'list ok': x => x.status === 200 });
            readLatency.add(r.timings.duration);
        }
        readCount.add(1);
    } else { // write async create
        const w = http.post(`${BASE_URL}${API_PREFIX}/trips/async`, payload, { headers, tags: { endpoint: 'async' } });
        check(w, { 'async ok': x => [200, 201, 202].includes(x.status) });
        writeLatency.add(w.timings.duration);
        writeCount.add(1);
    }
    sleep(1);
}

export function handleSummary(data) {
    return {
        [`replica-summary-${RUN_LABEL}.json`]: JSON.stringify({
            run_label: RUN_LABEL,
            vus: TARGET_VUS,
            read_p95: data.metrics.read_latency.values['p(95)'],
            write_p95: data.metrics.write_latency.values['p(95)'],
            read_avg: data.metrics.read_latency.values['avg'],
            write_avg: data.metrics.write_latency.values['avg'],
            reads: data.metrics.read_requests.values.count,
            writes: data.metrics.write_requests.values.count
        }, null, 2)
    };
}
