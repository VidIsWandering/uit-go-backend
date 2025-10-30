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

# --- Module Mạng (VPC, Subnets) ---
module "network" {
  source = "./modules/network"
  # Module này không cần biến đầu vào
}

# --- Module CSDL (RDS, ElastiCache, Secrets, SG) ---
module "database" {
  source = "./modules/database"

  # Truyền outputs từ module network vào
  vpc_id             = module.network.vpc_id
  vpc_cidr_block     = module.network.vpc_cidr_block
  private_subnet_ids = module.network.private_subnet_ids
}

# --- Module Triển khai (ECS, ALB, ECR, IAM) ---
module "ecs" {
  source = "./modules/ecs"

  # Lấy từ module network
  region             = module.network.region
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  # Lấy từ module database
  db_access_sg_id             = module.database.db_access_sg_id
  user_db_endpoint            = module.database.user_db_endpoint
  trip_db_endpoint            = module.database.trip_db_endpoint
  redis_endpoint              = module.database.redis_endpoint
  user_db_password_secret_arn = module.database.user_db_password_secret_arn
  trip_db_password_secret_arn = module.database.trip_db_password_secret_arn
}