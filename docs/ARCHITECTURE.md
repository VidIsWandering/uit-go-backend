# Sơ đồ Kiến trúc Hệ thống - UIT-Go (Giai đoạn 1)

Tài liệu này mô tả kiến trúc hệ thống backend UIT-Go cho Giai đoạn 1, bao gồm cả kiến trúc ứng dụng microservices và kiến trúc hạ tầng triển khai chi tiết trên AWS, đáp ứng các yêu cầu kỹ thuật trong Mục 3.2 của đề bài.

## 1. Sơ đồ Kiến trúc Triển khai trên AWS (Chi tiết Giai đoạn 1)

Sơ đồ dưới đây (vẽ bằng Mermaid) minh họa cách 3 microservices được triển khai bằng **AWS ECS Fargate** trong các **private subnets**, truy cập dữ liệu từ **RDS PostgreSQL** và **ElastiCache Redis** (cũng đặt trong private subnets), và nhận traffic từ Internet thông qua **Application Load Balancer (ALB)** đặt trong **public subnets**. Toàn bộ hạ tầng được quản lý bằng **Terraform (IaC)**.

```mermaid
graph TD
    %% Define main groups
    subgraph "Internet User"
        direction LR
        User["<U+1F464> Client (Mobile/Web)"]:::userStyle
    end

    subgraph "AWS Cloud (Region: ap-southeast-1)"
        direction TB

        subgraph VPC["VPC (uit-go-vpc: 10.0.0.0/16)"]
            direction LR

            %% Public Subnets Area
            subgraph PublicSubnets["Public Subnets"]
                ALB[("<U+26D1> ALB: uit-go-alb")]:::elbStyle
                IGW[("<U+1F310> Internet Gateway")]
                SubnetPubA["Subnet Public A"]
                SubnetPubB["Subnet Public B"]
            end

            %% Private Subnets Area
            subgraph PrivateSubnets["Private Subnets"]

                subgraph ECS["Amazon ECS (Fargate)"]
                    TaskUser["<U+1F4BB> Task: user-service (Java)"]:::ecsStyle
                    TaskTrip["<U+1F4BB> Task: trip-service (Java)"]:::ecsStyle
                    TaskDriver["<U+1F4BB> Task: driver-service (Node.js)"]:::ecsStyle
                end

                subgraph DBs["Managed Databases"]
                    RDSUser[("💾 RDS Postgres: user_db")]:::dbStyle
                    RDSTrip[("💾 RDS Postgres: trip_db")]:::dbStyle
                    Redis[("💾 ElastiCache Redis: driver_db")]:::dbStyle
                end

                SubnetPrivA["Subnet Private A"]
                SubnetPrivB["Subnet Private B"]
            end

            %% Security Components
            SG_ALB("🔒 SG: alb_sg"):::securityStyle
            SG_DB("🔒 SG: db_access"):::securityStyle
            Secrets("🔑 Secrets Manager"):::securityStyle
            IAMRoles("🧑‍💼 IAM Roles"):::securityStyle

            %% Placement & Connections (Simplified for clarity)
            ALB -- "Đặt tại Public Subnets" --> SubnetPubA & SubnetPubB
            IGW -- "Kết nối Public Subnets" --> SubnetPubA & SubnetPubB
            TaskUser -- "Chạy trong Private Subnets" --> SubnetPrivA & SubnetPrivB
            RDSUser -- "Đặt tại Private Subnets" --> SubnetPrivA & SubnetPrivB


            %% Main Connections
            User -- "HTTP/S Port 80" --> ALB

            ALB -- "Rule: /users*" --> TaskUser
            ALB -- "Rule: /trips*" --> TaskTrip
            ALB -- "Rule: /drivers*" --> TaskDriver

            TaskTrip -- "Internal REST" --> TaskUser
            TaskTrip -- "Internal REST" --> TaskDriver

            TaskUser -- "JDBC" --> RDSUser
            TaskTrip -- "JDBC" --> RDSTrip
            TaskDriver -- "Redis Client" --> Redis

            %% Security Connections (Illustrative)
            ALB -.-> SG_ALB
            TaskUser -.-> SG_DB
            RDSUser -.-> SG_DB
            Redis -.-> SG_DB
            TaskUser -.-> Secrets
            TaskUser -.-> IAMRoles

        end
    end

    %% Styles Definition using classDef
    classDef userStyle fill:#f3e5f5,stroke:#ab47bc,stroke-width:2px,color:#333;
    classDef elbStyle fill:#fff0b3,stroke:#ffb300,stroke-width:2px,color:#333;
    classDef ecsStyle fill:#e3f2fd,stroke:#64b5f6,stroke-width:1px,color:#333;
    classDef dbStyle fill:#e8f5e9,stroke:#81c784,stroke-width:1px,color:#333;
    classDef securityStyle fill:#ffebee,stroke:#e57373,stroke-width:1px,color:#333;
    classDef default fill:#fafafa,stroke:#666,stroke-width:1px,color:#333; /* Style for nodes without specific class */
```
