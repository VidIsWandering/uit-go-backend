# file: terraform/modules/ecs/variables.tf

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the main VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of IDs for public subnets (for ALB)"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of IDs for private subnets (for ECS Tasks)"
  type        = list(string)
}

variable "db_access_sg_id" {
  description = "Security Group ID for DB access (used by ECS Tasks)"
  type        = string
}

variable "user_db_endpoint" {
  description = "User DB endpoint"
  type        = string
}

variable "trip_db_endpoint" {
  description = "Trip DB endpoint"
  type        = string
}

variable "redis_endpoint" {
  description = "Redis endpoint"
  type        = string
}

variable "user_db_password_secret_arn" {
  description = "User DB password secret ARN"
  type        = string
}

variable "trip_db_password_secret_arn" {
  description = "Trip DB password secret ARN"
  type        = string
}