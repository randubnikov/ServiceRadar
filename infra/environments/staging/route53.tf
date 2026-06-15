resource "aws_route53_health_check" "services" {
  for_each = var.monitored_services

  fqdn              = each.value.url
  type              = each.value.type
  port              = each.value.port
  resource_path     = each.value.path
  request_interval  = 30
  failure_threshold = 3

  tags = {
    Name        = each.key
    Environment = var.environment
    Project     = "monitor"
  }
}
