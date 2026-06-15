output "lambda_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.incident_handler.arn
}
output "api_url" {
  description = "API Gateway URL"
  value       = aws_apigatewayv2_api.dashboard.api_endpoint
}

output "dlq_url" {
  description = "Dead letter queue URL for failed Lambda invocations"
  value       = aws_sqs_queue.lambda_dlq.url
}
