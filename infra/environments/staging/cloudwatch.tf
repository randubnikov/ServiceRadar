resource "aws_cloudwatch_metric_alarm" "service_health" {
  for_each = var.monitored_services

  alarm_name          = "${each.key}-health-${var.environment}"
  namespace           = "Route53"
  metric_name         = "HealthCheckStatus"
  comparison_operator = "LessThanThreshold"
  threshold           = 1
  evaluation_periods  = 2
  period              = 60
  statistic           = "Minimum"

  dimensions = {
    HealthCheckId = aws_route53_health_check.services[each.key].id
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn,
    module.lambda.lambda_arn
  ]

  tags = {
    Environment = var.environment
    Project     = "monitor"
  }
}