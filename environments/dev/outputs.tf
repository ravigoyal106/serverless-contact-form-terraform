output "dynamodb_table_name" {
  value = module.dynamodb_table.table_name
}

output "lambda_role_arn" {
  value = module.lambda_role.role_arn
}