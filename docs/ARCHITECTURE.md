# Sơ đồ Kiến trúc Hệ thống - UIT-Go (Giai đoạn 1)

Tài liệu này mô tả kiến trúc hệ thống backend UIT-Go cho Giai đoạn 1, bao gồm cả kiến trúc ứng dụng microservices và kiến trúc hạ tầng triển khai chi tiết trên AWS, đáp ứng các yêu cầu kỹ thuật trong Mục 3.2 của đề bài.

## 1. Sơ đồ Kiến trúc Triển khai trên AWS (Chi tiết Giai đoạn 1)

Sơ đồ dưới đây (vẽ bằng Mermaid) minh họa cách 3 microservices được triển khai bằng **AWS ECS Fargate** trong các **private subnets**, truy cập dữ liệu từ **RDS PostgreSQL** và **ElastiCache Redis** (cũng đặt trong private subnets), và nhận traffic từ Internet thông qua **Application Load Balancer (ALB)** đặt trong **public subnets**. Toàn bộ hạ tầng được quản lý bằng **Terraform (IaC)**.

```mermaid
graph LR %% Main direction Left-to-Right
    %% User outside AWS
    subgraph "Internet User"
        User["<U+1F464> Client (Mobile/Web)"]:::userStyle
    end

    %% AWS Cloud boundary
    subgraph AWS["AWS Cloud (Region: ap-southeast-1)"]
        direction TB %% Internal direction Top-to-Bottom

        %% Network Layer (VPC, Subnets, Gateway, ALB)
        subgraph VPC["VPC (uit-go-vpc: 10.0.0.0/16)"]
            direction TB

            subgraph PublicSubnets["Public Subnets"]
                 style PublicSubnets fill:#e6f2ff,stroke:#a6cfff
                 ALB[("<U+26D1> ALB: uit-go-alb")]:::elbStyle
                 IGW[("<U+1F310> Internet Gateway")]
                 SubnetPubA["Subnet A (1a)"]
                 SubnetPubB["Subnet B (1b)"]
                 ALB --> SubnetPubA & SubnetPubB
                 IGW --> SubnetPubA & SubnetPubB
            end

            subgraph PrivateSubnets["Private Subnets"]
                 style PrivateSubnets fill:#f0fff0,stroke:#90ee90
                 SubnetPrivA["Subnet A (1a)"]
                 SubnetPrivB["Subnet B (1b)"]
            end
        end

        %% Application & Data Layer (Inside Private Subnets conceptually)
        subgraph AppLayer["Application & Data Layer (in Private Subnets)"]
             direction LR

             subgraph ECS["Amazon ECS (Fargate)"]
                  style ECS fill:#e3f2fd,stroke:#64b5f6
                  TaskUser["<U+1F4BB> User Service (Java)"]:::ecsStyle
                  TaskTrip["<U+1F4BB> Trip Service (Java)"]:::ecsStyle
                  TaskDriver["<U+1F4BB> Driver Service (Node.js)"]:::ecsStyle
             end

             subgraph DBs["Managed Databases"]
                  style DBs fill:#e8f5e9,stroke:#81c784
                  RDSUser[("💾 RDS Postgres: user_db")]:::dbStyle
                  RDSTrip[("💾 RDS Postgres: trip_db")]:::dbStyle
                  Redis[("💾 ElastiCache Redis: driver_db")]:::dbStyle
             end
        end

        %% Security & Management Layer (Regional services)
         subgraph SecurityMgmt["Security & Management"]
              direction LR
              SG_ALB("🔒 SG: alb_sg"):::securityStyle
              SG_DB("🔒 SG: db_access"):::securityStyle
              Secrets("🔑 Secrets Manager"):::securityStyle
              IAMRoles("🧑‍💼 IAM Roles"):::securityStyle
         end

    end

    %% Connections
    User -- "HTTP/S Port 80" --> ALB
    ALB -- "Route /users*" --> TaskUser
    ALB -- "Route /trips*" --> TaskTrip
    ALB -- "Route /drivers*" --> TaskDriver

    TaskTrip -- "Internal REST" --> TaskUser
    TaskTrip -- "Internal REST" --> TaskDriver

    TaskUser -- "JDBC" --> RDSUser
    TaskTrip -- "JDBC" --> RDSTrip
    TaskDriver -- "Redis Client" --> Redis

    %% Security Interactions (Illustrative)
    ALB -.-> SG_ALB
    TaskUser -.-> SG_DB
    RDSUser -.-> SG_DB
    Redis -.-> SG_DB
    TaskUser -.-> Secrets & IAMRoles
    TaskTrip -.-> Secrets & IAMRoles
    TaskDriver -.-> IAMRoles


    %% Styles Definition using classDef
    classDef userStyle fill:#f3e5f5,stroke:#ab47bc,stroke-width:2px,color:#333;
    classDef elbStyle fill:#fff0b3,stroke:#ffb300,stroke-width:2px,color:#333;
    classDef ecsStyle fill:#e3f2fd,stroke:#64b5f6,stroke-width:1px,color:#333;
    classDef dbStyle fill:#e8f5e9,stroke:#81c784,stroke-width:1px,color:#333;
    classDef securityStyle fill:#ffebee,stroke:#e57373,stroke-width:1px,color:#333;
    classDef default fill:#fafafa,stroke:#666,stroke-width:1px,color:#333; %% Style for nodes without specific class
```
