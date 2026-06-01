# Zip the lambda function file automatically
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../../../lambda/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# IAM role that gives Lambda permission to run
resource "aws_iam_role" "lambda" {
  name = "${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Give Lambda permission to write to CloudWatch logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Give Lambda permission to connect to VPC (Aurora MySQL)
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# The actual Lambda function
resource "aws_lambda_function" "incident_handler" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.environment}-incident-handler"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  vpc_config {
    subnet_ids         = var.private_subnets
    security_group_ids = [var.security_group_id]
  }

  environment {
    variables = {
      DB_HOST     = var.aurora_endpoint
      DB_NAME     = "monitor_db"
      DB_USER     = var.db_username
      DB_PASSWORD = var.db_password
    }
  }

  tags = {
    Environment = var.environment
    Project     = "monitor"
  }
}