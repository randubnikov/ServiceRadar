variable "environment" {
  description = "staging or production"
  type        = string
}

variable "private_subnets" {
  description = "Private subnet IDs from VPC module"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID from Aurora module"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing DB credentials"
  type        = string
}

variable "db_host" {
  description = "Aurora MySQL endpoint"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}
