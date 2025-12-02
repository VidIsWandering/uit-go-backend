import http from "k6/http";
import { check, sleep } from "k6";

// WARMUP TEST - Prepare JVM JIT compilation for optimal performance
// Based on Round 2 discovery: 5-minute warmup eliminates 60% performance degradation
const WARMUP_DURATION = __ENV.WARMUP_DURATION || "5m";
const WARMUP_VUS = parseInt(__ENV.WARMUP_VUS || "50");

export const options = {
    stages: [
        { duration: "30s", target: WARMUP_VUS },     // Ramp up
        { duration: WARMUP_DURATION, target: WARMUP_VUS }, // Sustained load
        { duration: "30s", target: 0 },              // Ramp down
    ],
    thresholds: {
        // No strict thresholds - this is just warmup
        http_req_failed: ["rate<0.1"],  // Allow 10% errors during warmup
    },
};

const BASE_URL = __ENV.BASE_URL || "http://localhost:8081";
const API_PREFIX = __ENV.API_PREFIX || "";
const ASYNC = __ENV.ASYNC === "1";
const CREATE_ENDPOINT = ASYNC ? `${API_PREFIX}/trips/async` : `${API_PREFIX}/trips`;
const PASSENGER_TOKEN = __ENV.PASSENGER_TOKEN || 'INVALID_TOKEN_PLACEHOLDER';

export function setup() {
    console.log(`🔥 WARMUP: Starting ${WARMUP_DURATION} warmup with ${WARMUP_VUS} VUs`);
    console.log(`🎯 Target: JVM JIT compilation, connection pool warmup, query cache warmup`);
    return { token: PASSENGER_TOKEN };
}

export default function (data) {
    const params = {
        headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${data.token}`,
        },
    };

    // Simple trip creation request
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

    check(res, {
        "warmup request ok": (r) => r.status === 200 || r.status === 201 || r.status === 202,
    });

    sleep(0.5);
}

export function teardown(data) {
    console.log(`✅ WARMUP COMPLETE: JVM should be optimized now`);
}
