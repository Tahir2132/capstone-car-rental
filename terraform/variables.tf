variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Short project name, used in all resource names"
  type        = string
  default     = "capston-rent"
}

variable "alert_email" {
  description = "Email for the monthly budget alert (leave empty to skip the budget)"
  type        = string
  default     = ""
}

variable "budget_usd" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 10
}
