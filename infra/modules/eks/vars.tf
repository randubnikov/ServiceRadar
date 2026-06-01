variable "environment" {
  description = "staging or production"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID from the VPC module"
  type        = string
}

variable "private_subnets" {
  description = "Private subnet IDs from the VPC module"
  type        = list(string)
}