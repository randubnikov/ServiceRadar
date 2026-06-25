terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Bootstrap uses local state — this is intentional.
  # It manages the resources that other environments depend on for remote state.
}

provider "aws" {
  region = "us-east-1"
}

# S3 bucket for Terraform state (already exists; imported or created once)
resource "aws_s3_bucket" "tf_state" {
  bucket = "monitor-terraform-state-randubnikov"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Project = "monitor"
    Purpose = "terraform-state"
  }
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Project = "monitor"
    Purpose = "terraform-state-locking"
  }
}
