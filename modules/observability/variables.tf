variable "lambda_function_name" {
  type = string
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "alarm_email" {
  description = "Notified when the Lambda errors or gets throttled."
  type        = string
}