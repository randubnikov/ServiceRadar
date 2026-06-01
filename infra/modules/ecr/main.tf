resource "aws_ecr_repository" "monitor" {
  name                 = "${var.environment}-monitor"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
    Project     = "monitor"
  }
}