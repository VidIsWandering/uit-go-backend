# Availability Zone cho Read Replica (để khác AZ với primary)
variable "read_replica_az" {
  description = "Availability Zone for Trip DB read replica (e.g., ap-southeast-1b)"
  type        = string
  default     = "ap-southeast-1b"
}

# Toggle: enable creation of RDS primary instances (user_db, trip_db)
variable "enable_rds" {
  description = "Enable provisioning of primary RDS instances (user & trip). Set false for zero-cost hybrid."
  type        = bool
  default     = true
}

# Toggle: enable creation of trip read replica
variable "enable_read_replica" {
  description = "Enable provisioning of Trip DB read replica (extra cost)."
  type        = bool
  default     = false
}

# Toggle: enable elasticache redis resources
variable "enable_redis" {
  description = "Enable provisioning of ElastiCache Redis resources (cluster + subnet group)."
  type        = bool
  default     = false
}
# file: terraform/modules/database/variables.tf

variable "vpc_id" {
  description = "The ID of the main VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The CIDR block of the main VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of IDs for private subnets"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "Security group ID of the ALB (for service ingress rules)"
  type        = string
}