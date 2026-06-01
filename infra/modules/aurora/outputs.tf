output "aurora_endpoint" {
  description = "Aurora MySQL connection endpoint"
  value       = aws_rds_cluster.aurora.endpoint
}

output "aurora_database_name" {
  description = "Database name"
  value       = aws_rds_cluster.aurora.database_name
}