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

# Output Security Group IDs (segregated)
output "user_service_sg_id" {
  description = "Security group ID for user-service ECS tasks"
  value       = aws_security_group.user_service_sg.id
}

output "trip_service_sg_id" {
  description = "Security group ID for trip-service ECS tasks"
  value       = aws_security_group.trip_service_sg.id
}

output "driver_service_sg_id" {
  description = "Security group ID for driver-service ECS tasks"
  value       = aws_security_group.driver_service_sg.id
}

output "user_db_sg_id" {
  description = "Security group ID for user database"
  value       = aws_security_group.user_db_sg.id
}

output "trip_db_sg_id" {
  description = "Security group ID for trip database"
  value       = aws_security_group.trip_db_sg.id
}

output "redis_sg_id" {
  description = "Security group ID for Redis cluster"
  value       = aws_security_group.redis_sg.id
}