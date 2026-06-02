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
variable "alert_email" {
  description = "Email address to receive alerts"
  type        = string
}

variable "monitored_services" {
  description = "Map of services to monitor"
  type = map(object({
    url = string
  }))
  default = {
    "payment-api"  = { url = "pay.myapp.com" }
    "auth-service" = { url = "auth.myapp.com" }
    "test-service"   = { url = "httpbin.org" }
    "broken-service" = { url = "this-does-not-exist.com" }
  }
}
variable "environment" {
  description = "staging or production"
  type        = string
  default     = "staging"
}
