import http from "k6/http";
import { check, sleep } from "k6";

// Configuration for STRESS TEST (async variant)
export const options = {
  stages: [
    { duration: "30s", target: 150 },     // Faster warm up
    { duration: "1m", target: 400 },      // Moderate stress
    { duration: "1m", target: 700 },      // High stress
    { duration: "1m", target: 900 },      // Approaching peak
    { duration: "1m", target: 1000 },     // Peak load
    { duration: "1m", target: 1000 },     // Sustained peak
    { duration: "45s", target: 0 },       // Ramp down
  ],
  thresholds: {
    http_req_duration: ["p(95)<3000"],    // Expect lower p95 with async
    http_req_failed: ["rate<0.05"],
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
