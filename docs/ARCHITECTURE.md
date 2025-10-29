# Sơ đồ Kiến trúc Hệ thống - UIT-Go (Giai đoạn 1)

Tài liệu này mô tả kiến trúc hệ thống backend UIT-Go cho Giai đoạn 1, bao gồm cả kiến trúc ứng dụng microservices và kiến trúc hạ tầng triển khai chi tiết trên AWS, đáp ứng các yêu cầu kỹ thuật trong Mục 3.2 của đề bài.

## 1. Sơ đồ Kiến trúc Triển khai trên AWS (Chi tiết Giai đoạn 1)

Sơ đồ dưới đây (vẽ bằng Mermaid) minh họa cách 3 microservices được triển khai bằng **AWS ECS Fargate** trong các **private subnets**, truy cập dữ liệu từ **RDS PostgreSQL** và **ElastiCache Redis** (cũng đặt trong private subnets), và nhận traffic từ Internet thông qua **Application Load Balancer (ALB)** đặt trong **public subnets**. Toàn bộ hạ tầng được quản lý bằng **Terraform (IaC)**.

```mermaid
graph TD
    subgraph "Internet User"
        direction LR
        User["Client (Mobile/Web)"]
    end

    subgraph "AWS Cloud (Region: ap-southeast-1)"
        direction TB

        subgraph "VPC (uit-go-vpc: 10.0.0.0/16)"
            direction LR

            subgraph "Public Subnets (Access via Internet Gateway)"
                direction TB
                ALB[("ALB: uit-go-alb")]:::elbStyle
                SubnetPubA["Subnet Public A (10.0.1.0/24)"]
                SubnetPubB["Subnet Public B (10.0.2.0/24)"]
                ALB -- "Đặt tại" --> SubnetPubA
                ALB -- "Đặt tại" --> SubnetPubB
            end

            subgraph "Private Subnets (No direct Internet access)"
                direction TB

                subgraph "ECS Fargate Tasks"
                    TaskUser["Task: user-service (Java)"]:::ecsStyle
                    TaskTrip["Task: trip-service (Java)"]:::ecsStyle
                    TaskDriver["Task: driver-service (Node.js)"]:::ecsStyle
                end

                subgraph "Managed Databases"
                    RDSUser[("RDS Postgres: user_db")]:::dbStyle
                    RDSTrip[("RDS Postgres: trip_db")]:::dbStyle
                    Redis[("ElastiCache Redis: driver_db")]:::dbStyle
                end

                SubnetPrivA["Subnet Private A (10.0.101.0/24)"]
                SubnetPrivB["Subnet Private B (10.0.102.0/24)"]

                TaskUser -- "Chạy trong" --> SubnetPrivA & SubnetPrivB
                TaskTrip -- "Chạy trong" --> SubnetPrivA & SubnetPrivB
                TaskDriver -- "Chạy trong" --> SubnetPrivA & SubnetPrivB

                RDSUser -- "Đặt tại" --> SubnetPrivA & SubnetPrivB
                RDSTrip -- "Đặt tại" --> SubnetPrivA & SubnetPrivB
                Redis -- "Đặt tại" --> SubnetPrivA & SubnetPrivB
            end

            %% Connections
            User -- "HTTP/S Port 80" --> ALB

            ALB -- "Rule: /users* -> TG User" --> TaskUser
            ALB -- "Rule: /trips* -> TG Trip" --> TaskTrip
            ALB -- "Rule: /drivers* -> TG Driver" --> TaskDriver

            TaskTrip -- "Internal REST via VPC" --> TaskUser
            TaskTrip -- "Internal REST via VPC" --> TaskDriver

            TaskUser -- "JDBC (Port 5432 via SG)" --> RDSUser
            TaskTrip -- "JDBC (Port 5432 via SG)" --> RDSTrip
            TaskDriver -- "Redis Client (Port 6379 via SG)" --> Redis

        end
    end

    %% Styles
    classDef elbStyle fill:#f9f,stroke:#333,stroke-width:2px;
    classDef ecsStyle fill:#ccf,stroke:#333,stroke-width:2px;
    classDef dbStyle fill:#cfc,stroke:#333,stroke-width:2px;
```
