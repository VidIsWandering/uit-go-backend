# Khai báo nhà cung cấp (Provider) là AWS
#############################################
# Global Provider & Toggle Variables
# Toggle defaults are set to false to support Hybrid zero-cost mode.
#############################################

variable "enable_rds"               { type = bool default = false }
variable "enable_read_replica"      { type = bool default = false }
variable "enable_redis"             { type = bool default = false }
variable "enable_ecs"               { type = bool default = false }
variable "enable_alb"               { type = bool default = false }
variable "enable_services"          { type = bool default = false }
variable "enable_autoscaling"       { type = bool default = false }
variable "enable_ecr"               { type = bool default = false }
variable "enable_service_discovery" { type = bool default = false }

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

  # Network wiring
  vpc_id             = module.network.vpc_id
  vpc_cidr_block     = module.network.vpc_cidr_block
  private_subnet_ids = module.network.private_subnet_ids
  alb_sg_id          = module.network.alb_sg_id

  # Toggles
  enable_rds          = var.enable_rds
  enable_read_replica = var.enable_read_replica
  enable_redis        = var.enable_redis
}

# --- Module SQS (Message Queue) ---
module "sqs" {
  source = "./modules/sqs"
}

# --- Module Triển khai (ECS, ALB, ECR, IAM) ---
module "ecs" {
  source = "./modules/ecs"

  # Network wiring
  region             = module.network.region
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  alb_sg_id          = module.network.alb_sg_id

  # Security Groups (may be empty if DB/Redis disabled)
  user_service_sg_id   = module.database.user_service_sg_id
  trip_service_sg_id   = module.database.trip_service_sg_id
  driver_service_sg_id = module.database.driver_service_sg_id

  # Database / cache endpoints (empty strings if toggles off)
  user_db_endpoint         = module.database.user_db_endpoint
  trip_db_endpoint         = module.database.trip_db_endpoint
  trip_db_replica_endpoint = module.database.trip_db_replica_endpoint
  user_db_name             = module.database.user_db_name
  trip_db_name             = module.database.trip_db_name
  redis_endpoint           = module.database.redis_endpoint
  user_db_password_secret_arn = module.database.user_db_password_secret_arn
  trip_db_password_secret_arn = module.database.trip_db_password_secret_arn

  # Queue
  booking_queue_url = module.sqs.booking_queue_url
  booking_queue_arn = module.sqs.booking_queue_arn

  # Toggles
  enable_ecs               = var.enable_ecs
  enable_alb               = var.enable_alb
  enable_services          = var.enable_services
  enable_autoscaling       = var.enable_autoscaling
  enable_ecr               = var.enable_ecr
  enable_service_discovery = var.enable_service_discovery
}