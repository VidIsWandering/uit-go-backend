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