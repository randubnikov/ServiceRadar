resource "aws_secretsmanager_secret" "db" {
  name                    = "${var.environment}/monitor/db-credentials"
  description             = "Aurora MySQL credentials for ${var.environment} monitor"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}
