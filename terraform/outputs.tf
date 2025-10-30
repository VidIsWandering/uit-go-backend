# file: terraform/outputs.tf

output "user_db_endpoint" {
  value = module.database.user_db_endpoint
}

output "trip_db_endpoint" {
  value = module.database.trip_db_endpoint
}

output "user_db_password_secret_arn" {
  value = module.database.user_db_password_secret_arn
}

output "trip_db_password_secret_arn" {
  value = module.database.trip_db_password_secret_arn
}

output "redis_endpoint" {
  value = module.database.redis_endpoint
}

output "ecr_repository_urls" {
  value = module.ecs.ecr_repository_urls
}

output "alb_dns_name" {
  value = module.ecs.alb_dns_name
}