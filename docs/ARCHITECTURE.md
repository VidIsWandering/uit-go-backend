# Sơ đồ Kiến trúc Hệ thống - UIT-Go (Giai đoạn 1)

Tài liệu này mô tả kiến trúc hệ thống backend UIT-Go cho Giai đoạn 1, bao gồm cả kiến trúc ứng dụng microservices và kiến trúc hạ tầng triển khai chi tiết trên AWS, đáp ứng các yêu cầu kỹ thuật trong Mục 3.2 của đề bài.

## 1. Sơ đồ Kiến trúc Triển khai trên AWS (Chi tiết Giai đoạn 1)

Sơ đồ dưới đây (vẽ bằng Mermaid) minh họa cách 3 microservices được triển khai bằng **AWS ECS Fargate** trong các **private subnets**, truy cập dữ liệu từ **RDS PostgreSQL** và **ElastiCache Redis** (cũng đặt trong private subnets), và nhận traffic từ Internet thông qua **Application Load Balancer (ALB)** đặt trong **public subnets**. Toàn bộ hạ tầng được quản lý bằng **Terraform (IaC)**.

```mermaid
graph LR
    subgraph "Internet User"
        User["Client (Mobile/Web)"]
    end

    subgraph "AWS Cloud (Region: ap-southeast-1)"
        direction TB

        subgraph VPC["VPC (uit-go-vpc: 10.0.0.0/16)"]
            direction TB

            subgraph PublicSubnets["Public Subnets"]
                 ALB["ALB: uit-go-alb"]
                 IGW["Internet Gateway"]
                 SubnetPubA["Subnet A (1a)"]
                 SubnetPubB["Subnet B (1b)"]
                 ALB --> SubnetPubA & SubnetPubB
                 IGW --> SubnetPubA & SubnetPubB
            end

            subgraph PrivateSubnets["Private Subnets"]
                 SubnetPrivA["Subnet A (1a)"]
                 SubnetPrivB["Subnet B (1b)"]
                 %% ECS Tasks and Databases reside here
            end
        end

        subgraph AppLayer["Application & Data Layer (in Private Subnets)"]
             direction LR

             subgraph ECS["Amazon ECS (Fargate)"]
                  TaskUser["Task: user-service (Java)"]
                  TaskTrip["Task: trip-service (Java)"]
                  TaskDriver["Task: driver-service (Node.js)"]
             end

             subgraph DBs["Managed Databases"]
                  RDSUser[("RDS Postgres: user_db")]
                  RDSTrip[("RDS Postgres: trip_db")]
                  Redis[("ElastiCache Redis: driver_db")]
             end
        end

        subgraph SecurityMgmt["Security & Management"]
              direction LR
              SG_ALB("SG: alb_sg")
              SG_DB("SG: db_access")
              Secrets("Secrets Manager")
              IAMRoles("IAM Roles")
         end

    end

    %% Connections
    User -- "HTTP/S Port 80" --> ALB
    ALB -- "Route /users*" --> TaskUser
    ALB -- "Route /trips*" --> TaskTrip
    ALB -- "Route /drivers*" --> TaskDriver

    TaskTrip -- "Internal REST (VPC)" --> TaskUser
    TaskTrip -- "Internal REST (VPC)" --> TaskDriver

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

    %% Placement notes (Implied by connections and subgraph structure)
    %% ALB resides in Public Subnets
    %% ECS Tasks reside in Private Subnets
    %% Databases reside in Private Subnets
```
