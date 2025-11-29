import http from "k6/http";
import { check, sleep } from "k6";
import { SharedArray } from "k6/data";

// Configuration
export const options = {
  stages: [
    { duration: "10s", target: 10 }, // Ramp up to 10 users
    { duration: "30s", target: 100 }, // Spike to 100 users (Increased from 50 to test queue absorption)
    { duration: "10s", target: 0 }, // Ramp down
  ],
  thresholds: {
    http_req_duration: ["p(95)<500"], // 95% of requests should be below 500ms
    http_req_failed: ["rate<0.01"], // Less than 1% failure
  },
};

const BASE_URL = __ENV.BASE_URL || "http://localhost:8081";
const PASSENGER_TOKEN = __ENV.PASSENGER_TOKEN || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDIiLCJpYXQiOjE3NjQ0NDUwNjYsImV4cCI6MTc2NDUzMTQ2Nn0.YWSKNvT-cdoD26fMBPGKelXL7brGcy1yrLk4SmfXpo4';

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

  const res = http.post(`${BASE_URL}/trips`, payload, params);

  check(res, {
    "booking status is 200 or 201": (r) => r.status === 200 || r.status === 201,
    "response has tripId": (r) => r.json("id") !== undefined,
  });

  sleep(1);
}
