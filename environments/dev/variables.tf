variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short prefix used in resource names."
  type        = string
  default     = "serverless-contact-form"
}