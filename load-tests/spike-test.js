import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  stages: [
    { duration: "10s", target: 10 }, // Ramp up to 10 users
    { duration: "30s", target: 50 }, // Spike to 50 users
    { duration: "10s", target: 0 }, // Ramp down
  ],
};

const BASE_URL = "http://localhost:8088"; // Nginx gateway

export function setup() {
  // Register a user to get a token
  const email = `loadtest-${Date.now()}@example.com`;
  const password = "password123";

  const res = http.post(
    `${BASE_URL}/api/users`,
    JSON.stringify({
      email: email,
      password: password,
      fullName: "Load Test User",
      role: "PASSENGER",
      phone: "0123456789",
    }),
    {
      headers: { "Content-Type": "application/json" },
    }
  );

  check(res, { registered: (r) => r.status === 201 });

  const loginRes = http.post(
    `${BASE_URL}/api/sessions`,
    JSON.stringify({
      email: email,
      password: password,
    }),
    {
      headers: { "Content-Type": "application/json" },
    }
  );

  const token = loginRes.json("access_token");
  return { token };
}

export default function (data) {
  const payload = JSON.stringify({
    origin: { latitude: 10.762622, longitude: 106.660172 },
    destination: { latitude: 10.776054, longitude: 106.700967 },
    vehicleType: "CAR",
  });

  const params = {
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${data.token}`,
    },
  };

  const res = http.post(`${BASE_URL}/api/trips`, payload, params);

  check(res, {
    "is status 201": (r) => r.status === 201,
    "has trip id": (r) => r.json("id") !== undefined,
  });

  sleep(1);
}
