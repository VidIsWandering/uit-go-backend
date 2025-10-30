# file: terraform/modules/network/outputs.tf

output "vpc_id" {
  description = "The ID of the main VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the main VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of IDs for public subnets"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_subnet_ids" {
  description = "List of IDs for private subnets"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}