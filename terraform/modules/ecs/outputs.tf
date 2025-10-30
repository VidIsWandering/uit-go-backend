
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