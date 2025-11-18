# Driver Service (Node.js)

A lightweight service for driver location and status, using Redis geospatial.

## Requirements
- Node.js 18+
- Redis 7+

## Environment
- `REDIS_URL`: Redis connection string (default `redis://localhost:6379`)
- `PORT`: Optional server port (default `8082`)

Copy example when running standalone:
```bash
cp .env.example .env
```

## Run
### Option A: Standalone (local Redis)
```bash
npm install
node index.js
```
Server listens on `http://localhost:8082` by default.

### Option B: With root docker-compose
From repo root:
```bash
docker compose up -d driver-service redis-driver
```

## API Endpoints
- `GET /` → health/hello check
- `GET /health` → explicit healthcheck endpoint
- `PUT /drivers/:id/location` body `{ latitude, longitude }`
- `GET /drivers/search?lat=..&lng=..&radius=..` radius default 5km; returns ONLINE drivers only
- `PUT /drivers/:id/status` body `{ status: "ONLINE" | "OFFLINE" }`
- `GET /drivers/:id/location`

## Data Model in Redis
- Geospatial key: `driver_locations` (GEOADD, GEOSEARCH)
- Status key: `driver_status` (HSET driverId → ONLINE/OFFLINE)

## Test
```bash
npm install
npm test
```
Uses Jest to test service logic in `services/driver.service.js`.

## Notes
- When running in docker-compose, `REDIS_URL` is provided by compose env.
- This service has no direct dependency on Postgres.
