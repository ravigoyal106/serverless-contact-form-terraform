variable "aws_region" {
  description = "AWS region where the Terraform state bucket will be created."
  type = string
  default = "ap-south-1"
}

variable "project_name" {
  description = "project name"
  type = string
  default = "serverless-contact-form"
}

variable "state_bucket_suffix" {
    description = "s3 bucket suffix for unique bucket name"
    type = string
    default = "ravigoyal106"
  
}