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

output "user_db_name" {
  value = aws_db_instance.user_db.db_name
}

output "trip_db_name" {
  value = aws_db_instance.trip_db.db_name
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

# Output ID của security group db_access
output "db_access_sg_id" {
  value = aws_security_group.db_access.id 
}