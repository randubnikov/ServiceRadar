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
resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "lambda"
  endpoint  = module.lambda.lambda_arn
}

resource "aws_lambda_permission" "sns" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.lambda_arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts.arn
}
