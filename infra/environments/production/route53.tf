resource "aws_route53_health_check" "services" {
  for_each = var.monitored_services

  fqdn              = each.value.url
  type              = "HTTPS"
  port              = 443
  request_interval  = 30
  failure_threshold = 3

  tags = {
    Name        = each.key
    Environment = var.environment
    Project     = "monitor"
  }
}
