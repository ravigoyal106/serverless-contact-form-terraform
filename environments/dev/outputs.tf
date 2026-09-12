output "dynamodb_table_name" {
  value = module.dynamodb_table.table_name
}

output "lambda_role_arn" {
  value = module.lambda_role.role_arn
}

output "lambda_function_name" {
  value = module.contact_form_lambda.function_name
}

output "ses_verification_reminder" {
  value = "Check ${module.ses_identity.email_address}'s inbox and click the SES verification link before testing."
}

output "site_url" {
  description = "Open this in a browser to test the live form."
  value       = "http://${module.frontend_site.website_endpoint}"
}

output "api_invoke_url" {
  value = module.api_gateway.invoke_url
}