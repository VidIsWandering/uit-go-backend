import http from "k6/http";
import { check, sleep } from "k6";

// Configuration for STRESS TEST - Find Breaking Point
// Strategy: Gradually increase load to find bottleneck (where failure rate >10%)
export const options = {
  stages: [
    { duration: "1m", target: 100 },      // Baseline: Low load
    { duration: "1m", target: 200 },      // 2x: Moderate load
    { duration: "1m", target: 400 },      // 4x: High load
    { duration: "1m", target: 600 },      // 6x: Very high load
    { duration: "1m", target: 800 },      // 8x: Extreme load
    { duration: "1m", target: 1000 },     // 10x: Peak load
    { duration: "1m", target: 1200 },     // 12x: Beyond peak (find breaking point)
    { duration: "1m", target: 1200 },     // Sustained peak to confirm break
    { duration: "1m", target: 0 },        // Ramp down
  ],
  thresholds: {
    // Relaxed thresholds to observe degradation patterns
    http_req_duration: ["p(95)<10000"],   // Allow up to 10s to see where it breaks
    http_req_failed: ["rate<0.50"],       // Allow 50% failure to find exact breaking point
  },
};

const BASE_URL = __ENV.BASE_URL || "http://localhost:8081";
const ASYNC = __ENV.ASYNC === "1";
const CREATE_ENDPOINT = ASYNC ? "/trips/async" : "/trips";
const PASSENGER_TOKEN = __ENV.PASSENGER_TOKEN || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDIiLCJpYXQiOjE3NjQ0NDUwNjYsImV4cCI6MTc2NDUzMTQ2Nn0.YWSKNvT-cdoD26fMBPGKelXL7brGcy1yrLk4SmfXpo4';

export function setup() {
  return { token: PASSENGER_TOKEN };
}

export default function (data) {
  const params = {
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${data.token}`,
    },
  };

  const lat = 10.762622 + (Math.random() * 0.01 - 0.005);
  const lng = 106.660172 + (Math.random() * 0.01 - 0.005);

  const payload = JSON.stringify({
    origin: { latitude: lat, longitude: lng },
    destination: { latitude: 10.772622, longitude: 106.670172 }
  });

  const res = http.post(`${BASE_URL}${CREATE_ENDPOINT}`, payload, params);

  check(res, {
    "status accepted/created": (r) => r.status === 201 || r.status === 202,
  });

  // Lower sleep to amplify throughput with async
  sleep(0.2);
}
