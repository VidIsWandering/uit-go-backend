# Khai báo nhà cung cấp (Provider) là AWS
provider "aws" {
  region = "ap-southeast-1" # Singapore
}

# Khai báo Terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# --- Module Mạng (VPC, Subnets, ALB SG) ---
module "network" {
  source = "./modules/network"
  # Module này không cần biến đầu vào
}

# --- Module CSDL (RDS, ElastiCache, Secrets, Service SGs) ---
module "database" {
  source = "./modules/database"

  # Truyền outputs từ module network vào
  vpc_id             = module.network.vpc_id
  vpc_cidr_block     = module.network.vpc_cidr_block
  private_subnet_ids = module.network.private_subnet_ids

  # Truyền ALB SG từ module network
  alb_sg_id = module.network.alb_sg_id
}

# --- Module Triển khai (ECS, ALB, ECR, IAM) ---
module "ecs" {
  source = "./modules/ecs"

  # Lấy từ module network
  region             = module.network.region
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  alb_sg_id          = module.network.alb_sg_id

  # Lấy service security groups từ module database
  user_service_sg_id   = module.database.user_service_sg_id
  trip_service_sg_id   = module.database.trip_service_sg_id
  driver_service_sg_id = module.database.driver_service_sg_id

  # Lấy database endpoints và secrets từ module database
  user_db_endpoint            = module.database.user_db_endpoint
  trip_db_endpoint            = module.database.trip_db_endpoint
  user_db_name                = module.database.user_db_name
  trip_db_name                = module.database.trip_db_name
  redis_endpoint              = module.database.redis_endpoint
  user_db_password_secret_arn = module.database.user_db_password_secret_arn
  trip_db_password_secret_arn = module.database.trip_db_password_secret_arn
}