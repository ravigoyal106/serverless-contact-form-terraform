output "state_bucket_name" {
  description = "Name of the S3 bucket - backend bucket "
  value = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the state bucket"
  value = aws_s3_bucket.terraform_state.arn
}