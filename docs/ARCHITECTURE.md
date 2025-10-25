# Sơ đồ Kiến trúc Hệ thống - UIT-Go

Tài liệu này mô tả kiến trúc tổng quan của hệ thống backend UIT-Go, được xây dựng theo mô hình microservices.

## 1. Sơ đồ Kiến trúc

Sơ đồ dưới đây minh họa 3 microservices cơ bản và các CSDL riêng biệt của chúng, cùng với luồng giao tiếp nội bộ qua RESTful API.

```mermaid
graph TD
    subgraph "Hệ thống UIT-Go"
        direction LR

        subgraph "Role A (Java / Spring Boot)"
            direction TB
            US[UserService (Java :8080)]
            TS[TripService (Java :8081)]
        end

        subgraph "Role B (Node.js / Express)"
            direction TB
            DS[DriverService (Node.js :8082)]
        end

        subgraph "Cơ sở dữ liệu"
            direction TB
            DB_US[(<img src='[https://i.imgur.com/Gqlf3PD.png](https://i.imgur.com/Gqlf3PD.png)' width='30' /> Postgres-User)]
            DB_TS[(<img src='[https://i.imgur.com/Gqlf3PD.png](https://i.imgur.com/Gqlf3PD.png)' width='30' /> Postgres-Trip)]
            DB_DS[(<img src='[https://i.imgur.com/y3TqN3E.png](https://i.imgur.com/y3TqN3E.png)' width='30' /> Redis-Driver)]
        end

        %% Luồng giao tiếp Cột mốc 1
        TS -- "REST (GET /drivers/search)" --> DS

        %% Giao tiếp giả định (chưa làm)
        TS -. "REST (GET /users/me)" .-> US

        %% Kết nối CSDL
        US -- "JDBC" --> DB_US
        TS -- "JDBC" --> DB_TS
        DS -- "ioredis" --> DB_DS
    end