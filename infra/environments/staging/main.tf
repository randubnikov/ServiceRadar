module "vpc" {
  source      = "../../modules/vpc"
  environment = "staging"
  region      = "us-east-1"
}

module "eks" {
  source          = "../../modules/eks"
  environment     = "staging"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
}

module "aurora" {
  source               = "../../modules/aurora"
  environment          = "staging"
  vpc_id               = module.vpc.vpc_id
  private_subnets      = module.vpc.private_subnets
  private_subnets_cidr = ["10.0.1.0/24", "10.0.2.0/24"]
  db_username          = var.db_username
  db_password          = var.db_password
}

module "ecr" {
  source      = "../../modules/ecr"
  environment = "staging"
}
module "lambda" {
  source            = "../../modules/lambda"
  environment       = "staging"
  private_subnets   = module.vpc.private_subnets
  security_group_id = module.aurora.aurora_security_group_id
  aurora_endpoint   = module.aurora.aurora_endpoint
  db_username       = var.db_username
  db_password       = var.db_password
  db_host           = module.aurora.aurora_endpoint
  db_name           = "monitor_db"
  alert_email       = var.alert_email
}
