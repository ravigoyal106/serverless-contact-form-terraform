variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Short prefix used in resource names."
  type        = string
  default     = "serverless-contact-form"
}

variable "notification_email" {
  description = "Receives contact-form notifications and sends them. Must be verified in SES."
  type        = string
}


variable "site_bucket_suffix" {
  description = "Unique suffix for the frontend bucket."
  type        = string
}