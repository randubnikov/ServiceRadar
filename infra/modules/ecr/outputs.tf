output "repository_url" {
  description = "ECR repository URL for pushing Docker images"
  value       = aws_ecr_repository.monitor.repository_url
}