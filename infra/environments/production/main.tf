module "vpc" {
  source      = "../../modules/vpc"
  environment = "production"
  region      = "us-east-1"
}

module "eks" {
  source          = "../../modules/eks"
  environment     = "production"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
}

module "aurora" {
  source               = "../../modules/aurora"
  environment          = "production"
  vpc_id               = module.vpc.vpc_id
  private_subnets      = module.vpc.private_subnets
  private_subnets_cidr = ["10.0.1.0/24", "10.0.2.0/24"]
  db_username          = var.db_username
  db_password          = var.db_password
}

module "ecr" {
  source      = "../../modules/ecr"
  environment = "production"
}

module "lambda" {
  source            = "../../modules/lambda"
  environment       = "production"
  private_subnets   = module.vpc.private_subnets
  security_group_id = module.aurora.aurora_security_group_id
  db_host           = module.aurora.aurora_endpoint
  db_username       = var.db_username
  db_password       = var.db_password
  db_name           = "monitor_db"
}

resource "aws_s3_bucket" "dashboard" {
  bucket        = "serviceradar-dashboard-production"
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "dashboard" {
  bucket = aws_s3_bucket.dashboard.id
  index_document { suffix = "index.html" }
}

resource "aws_s3_bucket_public_access_block" "dashboard" {
  bucket                  = aws_s3_bucket.dashboard.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "dashboard" {
  bucket     = aws_s3_bucket.dashboard.id
  depends_on = [aws_s3_bucket_public_access_block.dashboard]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.dashboard.arn}/*"
    }]
  })
}