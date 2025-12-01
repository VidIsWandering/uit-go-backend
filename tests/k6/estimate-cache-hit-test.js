import http from 'k6/http';
import { check, sleep } from 'k6';
import { Trend, Counter } from 'k6/metrics';

/*
  Cache Hit Test (Estimate Endpoint)
  Mục tiêu: Chứng minh Redis cache làm giảm latency sau lần truy cập đầu (warm).
  Chiến lược: 1st call = cold, các call tiếp = warm. Dùng cùng origin/destination để tái sử dụng cache.
*/

const RUN_LABEL = __ENV.RUN_LABEL || 'round2-cache';
const BASE_URL = __ENV.BASE_URL || 'http://trip-service:8081';
const API_PREFIX = __ENV.API_PREFIX || '';
const PASSENGER_TOKEN = __ENV.PASSENGER_TOKEN || 'INVALID_TOKEN_PLACEHOLDER';
const TARGET_VUS = parseInt(__ENV.TARGET_VUS || '100');
const DURATION = __ENV.DURATION || '90s';

export const options = {
    vus: TARGET_VUS,
    duration: DURATION,
    thresholds: {
        'estimate_cold_latency': ['p(95)<1200'],
        'estimate_warm_latency': ['p(95)<400']
    }
};

const coldLatency = new Trend('estimate_cold_latency');
const warmLatency = new Trend('estimate_warm_latency');
const coldHits = new Counter('estimate_cold_requests');
const warmHits = new Counter('estimate_warm_requests');

export function setup() {
    return { token: PASSENGER_TOKEN };
}

export default function (data) {
    const headers = { 'Content-Type': 'application/json', Authorization: `Bearer ${data.token}` };
    // Cố định toạ độ để kích hoạt cache TTL
    const payload = JSON.stringify({ origin: { latitude: 10.7626, longitude: 106.6601 }, destination: { latitude: 10.7726, longitude: 106.6701 } });

    // Với mỗi VU: lần đầu coi là cold
    if (__ITER === 0) {
        const resCold = http.post(`${BASE_URL}${API_PREFIX}/trips/estimate`, payload, { headers, tags: { phase: 'cold' } });
        check(resCold, { 'cold accepted': r => [200, 201, 202].includes(r.status) });
        coldLatency.add(resCold.timings.duration);
        coldHits.add(1);
    } else {
        const resWarm = http.post(`${BASE_URL}${API_PREFIX}/trips/estimate`, payload, { headers, tags: { phase: 'warm' } });
        check(resWarm, { 'warm accepted': r => [200, 201, 202].includes(r.status) });
        warmLatency.add(resWarm.timings.duration);
        warmHits.add(1);
    }
    sleep(1);
}

export function handleSummary(data) {
    return {
        [`cache-summary-${RUN_LABEL}.json`]: JSON.stringify({
            run_label: RUN_LABEL,
            vus: TARGET_VUS,
            cold_p95: data.metrics.estimate_cold_latency?.values['p(95)'],
            warm_p95: data.metrics.estimate_warm_latency?.values['p(95)'],
            cold_avg: data.metrics.estimate_cold_latency?.values['avg'],
            warm_avg: data.metrics.estimate_warm_latency?.values['avg'],
            cold_requests: data.metrics.estimate_cold_requests?.values?.count,
            warm_requests: data.metrics.estimate_warm_requests?.values?.count
        }, null, 2)
    };
}
