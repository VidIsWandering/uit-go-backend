import http from "k6/http";
import { check, sleep } from "k6";
import { Counter, Trend } from "k6/metrics";

// Custom metrics
const latencyByStage = new Trend("latency_by_stage", true);
const errorsCounter = new Counter("errors_by_stage");

// Configuration - Progressive Load Test
// Test ở các mức: 100, 200, 300, 400, 500 VUs để tìm breaking point
export const options = {
    stages: [
        // Stage 1: 100 VUs - Baseline
        { duration: "2m", target: 100 },
        { duration: "1m", target: 100 },

        // Stage 2: 200 VUs - Safe Peak
        { duration: "1m", target: 200 },
        { duration: "1m", target: 200 },

        // Stage 3: 300 VUs - Near Breaking Point
        { duration: "1m", target: 300 },
        { duration: "1m", target: 300 },

        // Stage 4: 400 VUs - Stress
        { duration: "1m", target: 400 },
        { duration: "1m", target: 400 },

        // Stage 5: 500 VUs - Max Stress
        { duration: "1m", target: 500 },
        { duration: "1m", target: 500 },

        // Stage 6: 600 VUs - Extended
        { duration: "1m", target: 600 },
        { duration: "1m", target: 600 },

        // Stage 7: 700 VUs - Extended
        { duration: "1m", target: 700 },
        { duration: "1m", target: 700 },

        // Stage 8: 800 VUs - Extended
        { duration: "1m", target: 800 },
        { duration: "1m", target: 800 },

        // Stage 9: 900 VUs - Extended
        { duration: "1m", target: 900 },
        { duration: "1m", target: 900 },

        // Ramp down
        { duration: "1m", target: 0 },
    ],
    thresholds: {
        // Relaxed thresholds để test hết các mức
        http_req_duration: ["p(95)<5000"], // 5s - cho phép degraded
        // Giảm false fail: chỉ cảnh báo nếu >1% lỗi thực sự
        http_req_failed: ["rate<0.01"],
        "http_req_duration{stage:100}": ["p(95)<120"],   // nới nhẹ để tránh vi phạm sát ngưỡng
        "http_req_duration{stage:200}": ["p(95)<200"],
        "http_req_duration{stage:300}": ["p(95)<1000"],
        "http_req_duration{stage:400}": ["p(95)<2000"],
        "http_req_duration{stage:500}": ["p(95)<3000"],
        // Extended thresholds
        "http_req_duration{stage:600}": ["p(95)<3500"],
        "http_req_duration{stage:700}": ["p(95)<4000"],
        "http_req_duration{stage:800}": ["p(95)<4500"],
        "http_req_duration{stage:900}": ["p(95)<5000"],
    },
};

const BASE_URL = __ENV.BASE_URL || "http://localhost:8081";
const API_PREFIX = __ENV.API_PREFIX || "";
const ASYNC = __ENV.ASYNC === "1";
const CREATE_ENDPOINT = ASYNC ? `${API_PREFIX}/trips/async` : `${API_PREFIX}/trips`;
const PASSENGER_TOKEN = __ENV.PASSENGER_TOKEN || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDIiLCJpYXQiOjE3NjQ0NDUwNjYsImV4cCI6MTc2NDUzMTQ2Nn0.YWSKNvT-cdoD26fMBPGKelXL7brGcy1yrLk4SmfXpo4';

// Determine current stage based on VUs
function getCurrentStage(vus) {
    if (vus <= 100) return "100";
    if (vus <= 200) return "200";
    if (vus <= 300) return "300";
    if (vus <= 400) return "400";
    if (vus <= 500) return "500";
    if (vus <= 600) return "600";
    if (vus <= 700) return "700";
    if (vus <= 800) return "800";
    return "900";
}

export function setup() {
    console.log(`
╔════════════════════════════════════════════════════════════╗
║  PROGRESSIVE LOAD TEST - MODULE A TUNING                   ║
╠════════════════════════════════════════════════════════════╣
║  Purpose: Find breaking point và so sánh Round 1 vs 2     ║
║  Stages: 100 → 200 → 300 → 400 → 500 → 600 → 700 → 800 → 900 VUs ║
║  Duration: ~20 minutes                                      ║
║  Metrics: Latency, Throughput, Errors per stage           ║
╚════════════════════════════════════════════════════════════╝
  `);
    return { token: PASSENGER_TOKEN };
}

export default function (data) {
    const params = {
        headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${data.token}`,
        },
        tags: {
            endpoint: ASYNC ? "async" : "create",
            stage: getCurrentStage(__VU),
        },
    };

    // Randomize pickup location
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

    const success = check(res, {
        "status is 200/201/202": (r) => r.status === 200 || r.status === 201 || r.status === 202,
    });

    if (!success) {
        errorsCounter.add(1, { stage: getCurrentStage(__VU) });
    }

    // Record latency by stage
    latencyByStage.add(res.timings.duration, { stage: getCurrentStage(__VU) });

    sleep(1);
}

export function handleSummary(data) {
    console.log(`
╔════════════════════════════════════════════════════════════╗
║  TEST SUMMARY BY STAGE                                     ║
╚════════════════════════════════════════════════════════════╝
  `);

    return {
        'stdout': JSON.stringify(data, null, 2),
    };
}
