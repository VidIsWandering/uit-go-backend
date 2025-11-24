# file: terraform/modules/ecs/variables.tf

variable "region" {
  description = "AWS region"
  type        = string
}

variable "alb_sg_id" {
  description = "Security Group ID for Application Load Balancer (from network module)"
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

# Security group IDs from database module (segregated)
variable "user_service_sg_id" {
  description = "Security Group ID for user-service ECS tasks"
  type        = string
}

variable "trip_service_sg_id" {
  description = "Security Group ID for trip-service ECS tasks"
  type        = string
}

variable "driver_service_sg_id" {
  description = "Security Group ID for driver-service ECS tasks"
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

variable "user_db_name" {
  description = "User DB name"
  type        = string
  default     = "uit_user_db"
}

variable "trip_db_name" {
  description = "Trip DB name"
  type        = string
  default     = "uit_trip_db"
}

variable "booking_queue_url" {
  description = "URL of the SQS booking queue"
  type        = string
}

variable "booking_queue_arn" {
  description = "ARN of the SQS booking queue"
  type        = string
}