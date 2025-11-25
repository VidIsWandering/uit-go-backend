import http from "k6/http";
import { check, sleep } from "k6";

// Configuration for AVERAGE LOAD TEST
// Goal: Measure system performance under normal, sustained load
export const options = {
  stages: [
    { duration: "30s", target: 50 }, // Ramp up to 50 users (Normal load)
    { duration: "3m", target: 50 }, // Stay at 50 users for 3 minutes (Stability check)
    { duration: "30s", target: 0 }, // Ramp down
  ],
  thresholds: {
    http_req_duration: ["p(95)<500"], // 95% requests should be under 500ms
    http_req_failed: ["rate<0.01"], // Error rate should be under 1%
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

  if (res.status !== 200) {
    throw new Error(`Login failed: ${res.status} ${res.body}`);
  }

  return { token: res.json("token") };
}

export default function (data) {
  const params = {
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${data.token}`,
    },
  };

  // Scenario: Booking a trip
  const lat = 10.762622 + (Math.random() * 0.01 - 0.005);
  const lng = 106.660172 + (Math.random() * 0.01 - 0.005);

  const payload = JSON.stringify({
    origin: {
      latitude: lat,
      longitude: lng,
      address: "Average Load Pickup",
    },
    destination: {
      latitude: 10.772622,
      longitude: 106.670172,
      address: "Average Load Destination",
    },
    vehicleType: "CAR_4_SEAT",
  });

  const res = http.post(`${BASE_URL}/trips`, payload, params);

  check(res, {
    "status is 200/201": (r) => r.status === 200 || r.status === 201,
  });

  sleep(1); // Think time: 1 second between requests
}
