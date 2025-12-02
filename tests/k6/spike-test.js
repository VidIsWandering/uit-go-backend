import http from "k6/http";
import { check, sleep } from "k6";
import { Counter } from "k6/metrics";

// Configuration for SPIKE TEST - Baseline comparison with Round 1
// Round 1 baseline: 100 VUs, p95=1.94s, error=0%, RPS=29
const TARGET_VUS = parseInt(__ENV.TARGET_VUS || __ENV.TARGET_LOAD || "100");
const RAMP_UP_TIME = __ENV.RAMP_UP_TIME || "10s";
const SPIKE_DURATION = __ENV.SPIKE_DURATION || "30s";
const RAMP_DOWN_TIME = __ENV.RAMP_DOWN_TIME || "10s";
const ASYNC_P95_THRESHOLD = __ENV.ASYNC_P95_THRESHOLD || "400";
const RUN_LABEL = __ENV.RUN_LABEL || "round2-spike"; // dùng để phân loại evidence

// Metrics bổ sung để chẩn đoán lỗi bất thường 100% fail
const statusCounts = new Counter("status_counts");
const failedBodiesSample = new Counter("failed_bodies_sampled");

export const options = {
  stages: [
    { duration: RAMP_UP_TIME, target: Math.floor(TARGET_VUS * 0.1) },  // Ramp up to 10% of target
    { duration: SPIKE_DURATION, target: TARGET_VUS },                   // Spike to target VUs
    { duration: RAMP_DOWN_TIME, target: 0 },                            // Ramp down
  ],
  thresholds: {
    http_req_duration: ["p(95)<2500"],        // Optimized for sub-2.5s latency
    http_req_failed: ["rate<0.01"],           // Error rate
    "http_req_duration{endpoint:create}": ["p(95)<2500"],
    // Dùng ngưỡng động cho async endpoint tùy theo tải
    [`http_req_duration{endpoint:async}`]: ["p(95)<" + ASYNC_P95_THRESHOLD],
  },
  summaryTrendStats: ["min", "avg", "med", "max", "p(90)", "p(95)", "p(99)"],
};

const BASE_URL = __ENV.BASE_URL || "http://localhost:8081";
const API_PREFIX = __ENV.API_PREFIX || ""; // use "/api" when going through nginx
const ASYNC = __ENV.ASYNC === "1";
const CREATE_ENDPOINT = ASYNC ? `${API_PREFIX}/trips/async` : `${API_PREFIX}/trips`;
const PASSENGER_TOKEN = __ENV.PASSENGER_TOKEN || 'INVALID_TOKEN_PLACEHOLDER';

// Setup: Use pre-generated JWT token
export function setup() {
  return { token: PASSENGER_TOKEN };
}

export default function (data) {
  const params = {
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${data.token}`,
    },
    tags: { endpoint: ASYNC ? "async" : "create" },  // Tag for per-endpoint metrics
  };

  // Scenario: Booking a trip
  // Randomize pickup location slightly around HCM
  const lat = 10.762622 + (Math.random() * 0.01 - 0.005);
  const lng = 106.660172 + (Math.random() * 0.01 - 0.005);

  const payload = JSON.stringify({
    origin: {
      latitude: lat,
      longitude: lng
    },
    destination: {
      latitude: 10.772622,
      longitude: 106.670172
    }
  });

  const res = http.post(`${BASE_URL}${CREATE_ENDPOINT}`, payload, params);

  // Chấp nhận cả 202 và tạm thời ghi nhận 4xx/5xx phục vụ phân tích
  const passed = check(res, {
    "status 200/201/202": (r) => r.status === 200 || r.status === 201 || r.status === 202,
  });

  statusCounts.add(1, { code: String(res.status) });

  if (!passed) {
    // Lưu mẫu body (đếm) để sau đọc trong Influx nếu cần
    failedBodiesSample.add(1);
    if (__ITER % 1000 === 0) {
      console.log(`sample status=${res.status} body=${(res.body || '').substring(0, 120)}`);
    }
  }

  sleep(0.5);
}

// Custom summary: ghi file JSON để làm evidence
export function handleSummary(data) {
  const summary = {
    run_label: RUN_LABEL,
    target_vus: TARGET_VUS,
    async_mode: ASYNC,
    thresholds: { async_p95: ASYNC_P95_THRESHOLD },
    metrics: {
      http_req_duration: data.metrics.http_req_duration,
      http_req_failed: data.metrics.http_req_failed,
      iteration_duration: data.metrics.iteration_duration,
      status_counts: data.metrics.status_counts ? data.metrics.status_counts.values : null,
    }
  };
  return {
    [`spike-summary-${RUN_LABEL}.json`]: JSON.stringify(summary, null, 2),
    stdout: JSON.stringify({ label: RUN_LABEL, p95: data.metrics.http_req_duration.values['p(95)'], vus: TARGET_VUS }) + "\n"
  };
}
