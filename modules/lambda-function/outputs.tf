output "function_name" {
  value = aws_lambda_function.this.function_name
}

output "function_arn" {
  value = aws_lambda_function.this.arn
}

output "invoke_arn" {
  description = "Needed by API Gateway's Lambda integration in Step 4."
  value       = aws_lambda_function.this.invoke_arn
}

output "log_group_name" {
  value = "/aws/lambda/${aws_lambda_function.this.function_name}"
}