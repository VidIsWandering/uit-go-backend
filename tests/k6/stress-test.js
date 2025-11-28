import http from "k6/http";
import { check, sleep } from "k6";

// Configuration for STRESS TEST
// Goal: Find the breaking point of the system
export const options = {
  stages: [
    { duration: "30s", target: 50 }, // Stage 1: Warm up (Normal load)
    { duration: "1m", target: 100 }, // Stage 2: Heavy load
    { duration: "1m", target: 300 }, // Stage 3: Stress load (Safe limit for laptop)
    { duration: "30s", target: 500 }, // Stage 4: Breaking point attempt (Reduced from 1000)
    { duration: "30s", target: 0 }, // Ramp down
  ],
  thresholds: {
    // We accept higher latency in stress test, but we want to know when it fails
    http_req_duration: ["p(95)<2000"], // 95% requests should be under 2s (if higher -> system is struggling)
    http_req_failed: ["rate<0.05"], // Error rate should be under 5% (if higher -> system is broken)
  },
};

const BASE_URL = "http://localhost:8088/api";

// Setup: Login once to get a token
export function setup() {
  const payload = JSON.stringify({
    email: "test@uit.edu.vn",
    password: "password123",
  });

  const params = {
    headers: {
      "Content-Type": "application/json",
    },
  };

  const res = http.post(`${BASE_URL}/sessions`, payload, params);

  // If login fails, stop the test immediately
  if (res.status !== 200) {
    throw new Error(`Login failed: ${res.status} ${res.body}`);
  }

  return { token: res.json("access_token") };
}

export default function (data) {
  const params = {
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${data.token}`,
    },
  };

  // Scenario: Booking a trip
  // Randomize pickup location slightly around HCM
  const lat = 10.762622 + (Math.random() * 0.01 - 0.005);
  const lng = 106.660172 + (Math.random() * 0.01 - 0.005);

  const payload = JSON.stringify({
    origin: {
      latitude: lat,
      longitude: lng,
      address: "Stress Test Pickup",
    },
    destination: {
      latitude: 10.772622,
      longitude: 106.670172,
      address: "Stress Test Destination",
    },
    vehicleType: "CAR_4_SEAT",
  });

  const res = http.post(`${BASE_URL}/trips`, payload, params);

  check(res, {
    "status is 200/201": (r) => r.status === 200 || r.status === 201,
  });

  // In stress test, we reduce sleep time to generate more pressure
  sleep(0.5);
}
