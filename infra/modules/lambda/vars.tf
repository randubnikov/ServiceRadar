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

variable "aurora_endpoint" {
  description = "Aurora MySQL endpoint from Aurora module"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}
variable "db_host" {
  description = "Aurora MySQL endpoint"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}
