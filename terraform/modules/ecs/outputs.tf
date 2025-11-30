
# Output URL của ECR Repositories
output "ecr_repository_urls" {
  description = "URLs of the ECR repositories (empty map if ECR disabled)"
  value       = var.enable_ecr ? { for k, repo in aws_ecr_repository.service_ecr : k => repo.repository_url } : {}
}

# Output DNS Name của Application Load Balancer
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer (empty if ALB disabled)"
  value       = var.enable_alb ? aws_lb.main[0].dns_name : ""
}