resource "aws_sns_topic" "alerts" {
  name = "${var.environment}-monitor-alerts"

  tags = {
    Environment = var.environment
    Project     = "monitor"
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}