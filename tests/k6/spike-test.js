import http from "k6/http";
import { check, sleep } from "k6";
import { SharedArray } from "k6/data";

// Configuration
export const options = {
  stages: [
    { duration: "10s", target: 10 }, // Ramp up to 10 users
    { duration: "30s", target: 50 }, // Spike to 50 users
    { duration: "10s", target: 0 }, // Ramp down
  ],
  thresholds: {
    http_req_duration: ["p(95)<500"], // 95% of requests should be below 500ms
    http_req_failed: ["rate<0.01"], // Less than 1% failure
  },
};

const BASE_URL = "http://localhost:8088/api";

// Setup: Login once to get a token (or use a fixed test token if auth is mocked)
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

  check(res, {
    "login successful": (r) => r.status === 200,
    "has token": (r) => r.json("access_token") !== undefined,
  });

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
      address: "Test Pickup Point",
    },
    destination: {
      latitude: 10.772622,
      longitude: 106.670172,
      address: "Test Destination",
    },
    vehicleType: "CAR_4_SEAT",
  });

  const res = http.post(`${BASE_URL}/trips`, payload, params);

  check(res, {
    "booking status is 200 or 201": (r) => r.status === 200 || r.status === 201,
    "response has tripId": (r) => r.json("id") !== undefined,
  });

  sleep(1);
}
