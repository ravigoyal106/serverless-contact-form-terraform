variable "api_name" {
  type = string
}

variable "lambda_invoke_arn" {
  description = "Lambda's invoke_arn output used as the integration target."
  type        = string
}

variable "lambda_function_name" {
  description = "Lambda's function name used to grant API Gateway invoke permission."
  type        = string
}

variable "route_path" {
  type    = string
  default = "/contact"
}

variable "route_method" {
  type    = string
  default = "POST"
}

variable "cors_allow_origin" {
  description = "Origin allowed to call this API. '*' for initial testing tighten once the frontend's real URL is known."
  type        = string
  default     = "*"
}