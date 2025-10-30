# Nginx Reverse Proxy (API Gateway) for UIT-Go

This document shows a simple Nginx configuration acting as a lightweight API Gateway / reverse proxy for local development.

Routing rules:
- /api/users/** -> http://user-service:8080
- /api/trips/** -> http://trip-service:8081

Security:
- Optionally, the gateway can enforce a global auth header (e.g., check `Authorization` header) or pass through to upstream services.

## nginx.conf (sample)

```nginx
worker_processes 1;

events { worker_connections 1024; }

http {
    upstream user_service {
        server user-service:8080;
    }

    upstream trip_service {
        server trip-service:8081;
    }

    upstream auth_service {
        server auth-service:3000;
    }

    server {
        listen 80;

        # Validate requests via auth-service before proxying (using auth_request)
        location = /_auth_validate {
            internal;
            proxy_pass http://auth_service/validate;
            proxy_set_header Content-Type "application/json";
            proxy_pass_request_body off;
            proxy_set_header       X-Original-URI $request_uri;
            proxy_set_header       Authorization $http_authorization;
        }

        # Enforce authentication by using auth_request; remove 'auth_request' lines if you do not want enforcement
        location /api/users/ {
            auth_request /_auth_validate;
            proxy_pass http://user_service/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            # Pass authenticated user info from auth service (optional)
            proxy_set_header X-Auth-User $upstream_http_x_auth_user;
        }

        location /api/trips/ {
            auth_request /_auth_validate;
            proxy_pass http://trip_service/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Auth-User $upstream_http_x_auth_user;
        }

        location /health {
            return 200 '{"status":"ok"}';
            add_header Content-Type application/json;
        }
    }
}
```



## Running locally with Docker Compose (example)
Add an nginx service to your `docker-compose.yml` with the following snippet:

```yaml
  nginx:
    image: nginx:stable-alpine
    ports:
      - "8088:80"
    volumes:
      - ./docs/nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - user-service
      - trip-service
```

Then visit `http://localhost:8088/api/users/` to reach the user-service through gateway.

## Notes
- This is a lightweight development gateway. For production consider using a proper API Gateway (Kong, Ambassador, AWS API Gateway, or Spring Cloud Gateway) that supports auth plugins, rate limiting, circuit breaking, and observability.
- If you enable global auth at the gateway, ensure your services trust the gateway and/or validate forwarded tokens properly.
