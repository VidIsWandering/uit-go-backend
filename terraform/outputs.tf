# file: terraform/outputs.tf

# Output địa chỉ endpoint của User DB
output "user_db_endpoint" {
  description = "Endpoint for the User RDS database"
  value       = aws_db_instance.user_db.address
}

# Output địa chỉ endpoint của Trip DB
output "trip_db_endpoint" {
  description = "Endpoint for the Trip RDS database"
  value       = aws_db_instance.trip_db.address
}

# Output ARN của secret chứa mật khẩu User DB
output "user_db_password_secret_arn" {
  description = "ARN of the Secrets Manager secret for User DB password"
  value       = aws_secretsmanager_secret.user_db_password.arn
}

# Output ARN của secret chứa mật khẩu Trip DB
output "trip_db_password_secret_arn" {
  description = "ARN of the Secrets Manager secret for Trip DB password"
  value       = aws_secretsmanager_secret.trip_db_password.arn
}

# Output địa chỉ endpoint của Redis Cluster
output "redis_endpoint" {
  description = "Primary endpoint for the ElastiCache Redis cluster"
  # ElastiCache trả về endpoint chính qua thuộc tính này
  value = aws_elasticache_cluster.redis_cluster.cache_nodes[0].address
}

# Output URL của ECR Repositories
output "ecr_repository_urls" {
  description = "URLs of the ECR repositories"
  value = {
    for k, repo in aws_ecr_repository.service_ecr : k => repo.repository_url
  }
  # value sẽ là một map như: { user = "...", trip = "...", driver = "..." }
}

# Output DNS Name của Application Load Balancer
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}