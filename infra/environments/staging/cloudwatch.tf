resource "aws_cloudwatch_metric_alarm" "service_health" {
  for_each = var.monitored_services

  alarm_name          = "${each.key}-health-${var.environment}"
  namespace           = "AWS/Route53"
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
    aws_sns_topic.alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.alerts.arn
  ]

  insufficient_data_actions = [
    aws_sns_topic.alerts.arn
  ]

  depends_on = [aws_lambda_permission.sns]

  tags = {
    Environment = var.environment
    Project     = "monitor"
  }
}
