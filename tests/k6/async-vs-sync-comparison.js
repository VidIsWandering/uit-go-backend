import http from 'k6/http';
import { check, sleep } from 'k6';
import { Trend } from 'k6/metrics';

/*
  Async vs Sync Comparison
  Mục tiêu: Chứng minh tối ưu async booking (Module A) nhanh hơn / tail ít hơn so với sync.
  Chiến lược: Mỗi VU gửi 1 request async rồi 1 request sync trong cùng iteration.
  Ghi lại latency từng loại qua custom Trend.
*/

const RUN_LABEL = __ENV.RUN_LABEL || 'round2-async-sync';
const BASE_URL = __ENV.BASE_URL || 'http://trip-service:8081';
const API_PREFIX = __ENV.API_PREFIX || '';
const PASSENGER_TOKEN = __ENV.PASSENGER_TOKEN || 'INVALID_TOKEN_PLACEHOLDER';
const TARGET_VUS = parseInt(__ENV.TARGET_VUS || '200');

export const options = {
    vus: TARGET_VUS,
    duration: __ENV.DURATION || '2m',
    thresholds: {
        'async_latency': ['p(95)<1500'],
        'sync_latency': ['p(95)<2500']
    }
};

const asyncLatency = new Trend('async_latency');
const syncLatency = new Trend('sync_latency');

export function setup() { return { token: PASSENGER_TOKEN }; }

export default function (data) {
    const headers = { 'Content-Type': 'application/json', Authorization: `Bearer ${data.token}` };

    const lat = 10.7626 + (Math.random() * 0.01 - 0.005);
    const lng = 106.6601 + (Math.random() * 0.01 - 0.005);
    const payload = JSON.stringify({ origin: { latitude: lat, longitude: lng }, destination: { latitude: 10.7726, longitude: 106.6701 } });

    // Async
    const asyncRes = http.post(`${BASE_URL}${API_PREFIX}/trips/async`, payload, { headers, tags: { endpoint: 'async' } });
    check(asyncRes, { 'async accepted': r => [200, 201, 202].includes(r.status) });
    asyncLatency.add(asyncRes.timings.duration);

    // Sync
    const syncRes = http.post(`${BASE_URL}${API_PREFIX}/trips`, payload, { headers, tags: { endpoint: 'create' } });
    check(syncRes, { 'sync accepted': r => [200, 201, 202].includes(r.status) });
    syncLatency.add(syncRes.timings.duration);

    sleep(1);
}

export function handleSummary(data) {
    return {
        [`async-sync-summary-${RUN_LABEL}.json`]: JSON.stringify({
            run_label: RUN_LABEL,
            target_vus: TARGET_VUS,
            async_p95: data.metrics.async_latency.values['p(95)'],
            sync_p95: data.metrics.sync_latency.values['p(95)'],
            async_avg: data.metrics.async_latency.values['avg'],
            sync_avg: data.metrics.sync_latency.values['avg']
        }, null, 2)
    };
}
