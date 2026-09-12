variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
}

variable "source_dir" {
  description = "Path to the directory containing the Lambda source code."
  type        = string
}

variable "handler" {
  description = "Entry point, in the form file.exportedFunction."
  type        = string
  default     = "index.handler"
}

variable "runtime" {
  description = "Lambda runtime identifier."
  type        = string
  default     = "nodejs22.x"
}

variable "role_arn" {
  description = "ARN of the IAM execution role this function assumes."
  type        = string
}

variable "timeout" {
  description = "Function timeout, in seconds."
  type        = number
  default     = 10
}

variable "environment_variables" {
  description = "Environment variables injected into the function."
  type        = map(string)
  default     = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}