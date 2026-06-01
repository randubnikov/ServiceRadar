variable "environment" {
  description = "staging or production"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID from the VPC module"
  type        = string
}

variable "private_subnets" {
  description = "Private subnet IDs from VPC module"
  type        = list(string)
}

variable "private_subnets_cidr" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
}

variable "db_username" {
  description = "Aurora MySQL username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Aurora MySQL password"
  type        = string
  sensitive   = true
}