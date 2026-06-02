output "ecr_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "aurora_endpoint" {
  description = "Aurora MySQL endpoint"
  value       = module.aurora.aurora_endpoint
}

output "sns_topic_arn" {
  description = "SNS topic ARN"
  value       = aws_sns_topic.alerts.arn
}
