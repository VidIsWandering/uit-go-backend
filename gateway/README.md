# API Gateway - Nginx Configuration

This directory contains the Nginx reverse proxy configuration for the UIT-Go backend API gateway.

## Architecture

```
Client → Nginx (port 8088) → Backend Services
                            ├─ user-service:8080
                            ├─ trip-service:8081
                            ├─ driver-service:8082
                            └─ auth-service:3000 (internal)
```

## Routes

### Public Endpoints (No Authentication)

| Method | Path | Backend | Description |
|--------|------|---------|-------------|
| POST | `/api/users` | user-service:8080/users | User registration |
| POST | `/api/sessions` | user-service:8080/sessions | User login |
| POST | `/api/trips/estimate` | trip-service:8081/trips/estimate | Price estimation |
| GET | `/health` | nginx | Gateway health check |

### Protected Endpoints (Require JWT)

All protected endpoints require `Authorization: Bearer <token>` header.

| Method | Path | Backend | Description |
|--------|------|---------|-------------|
| POST | `/api/trips` | trip-service:8081/trips | Create trip |
| GET/POST | `/api/trips/*` | trip-service:8081/trips/* | Trip operations (cancel, complete, etc.) |
| GET | `/api/users/me` | user-service:8080/users/me | Get current user |
| GET/POST | `/api/users/*` | user-service:8080/users/* | User operations |
| GET | `/api/drivers/search` | driver-service:8082/drivers/search | Search nearby drivers |
| GET/POST | `/api/drivers/*` | driver-service:8082/drivers/* | Driver operations |

## Authentication Flow

1. **Client** sends request to protected endpoint with JWT token
2. **Nginx** makes subrequest to `/_auth_validate` (internal)
3. **auth-service** validates JWT:
   - Returns `200 OK` if valid → request continues to backend
   - Returns `401 Unauthorized` if invalid → nginx returns 401 to client
4. **Backend service** receives request with original Authorization header

## Key Features

### 🔒 JWT Authentication via auth_request
- Centralized auth validation through auth-service
- No auth logic duplication in backend services
- Auth-service validates token signature and expiration

### 🔀 Path Rewriting
```nginx
# /api/trips/123/cancel → /trips/123/cancel
rewrite ^/api/trips/(.*)$ /trips/$1 break;
```

### 📝 Header Forwarding
All requests include:
- `Authorization`: JWT token
- `X-Real-IP`: Client IP
- `X-Forwarded-For`: Proxy chain
- `X-Forwarded-Proto`: Original protocol (http/https)
- `Host`: Original host header

### 🚫 Security
- `/_auth_validate` endpoint is `internal` (not accessible from outside)
- `proxy_pass_request_body off` for auth validation (prevents body parsing timeout)

## Configuration

### Upstream Definitions
```nginx
upstream user_service {
    server user-service:8080;
}

upstream trip_service {
    server trip-service:8081;
}

upstream driver_service {
    server driver-service:8082;
}
```

Service names resolve via Docker Compose network DNS.

### Testing

```bash
# Test public endpoint
curl http://localhost:8088/api/trips/estimate \
  -H "Content-Type: application/json" \
  -d '{"origin":{"latitude":10.87,"longitude":106.803},"destination":{"latitude":10.88,"longitude":106.813}}'

# Test protected endpoint (replace <token> with actual JWT)
curl http://localhost:8088/api/trips \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"origin":{"latitude":10.87,"longitude":106.803},"destination":{"latitude":10.88,"longitude":106.813}}'

# Test health check
curl http://localhost:8088/health
```

## Troubleshooting

### 401 Unauthorized on Protected Endpoints
1. Check JWT_SECRET is same across user-service, trip-service, and auth-service
2. Verify token not expired (24h default)
3. Check Authorization header format: `Bearer <token>` (note the space)
4. View auth-service logs: `docker logs uit-go-backend-auth-service-1`

### 502 Bad Gateway
1. Check backend service is running: `docker ps`
2. Check service health: `curl http://localhost:8080/actuator/health`
3. View nginx logs: `docker logs uit-go-backend-nginx-1`

### 504 Gateway Timeout
1. Check auth-service response time
2. Verify bodyParser not applied globally in auth-service (causes timeout on subrequests)
3. Check nginx logs for "upstream timed out" messages

## Future Enhancements

- [ ] Add CORS headers for web/mobile clients
- [ ] Implement rate limiting (limit_req_zone)
- [ ] Add request logging with custom format
- [ ] Enable gzip compression
- [ ] Add SSL/TLS termination
- [ ] Implement circuit breaker pattern
- [ ] Add request/response size limits
- [ ] Configure timeout values per route

## Related Documentation

- [API Contracts](../docs/API_CONTRACTS.md)
- [NGINX Gateway Documentation](../docs/NGINX_GATEWAY.md)
- [Testing Checklist](../docs/TESTING_CHECKLIST.md)
