output "role_arn" {
  description = "ARN of the Lambda execution role."
  value       = aws_iam_role.lambda_execution.arn
}

output "role_name" {
  value = aws_iam_role.lambda_execution.name
}