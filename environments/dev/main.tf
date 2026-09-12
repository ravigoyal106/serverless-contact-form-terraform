provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

module "dynamodb_table" {
  source = "../../modules/dynamodb-table"

  table_name = "${var.project_name}-submissions-dev"
  hash_key   = "submissionId"
}

module "lambda_role" {
  source = "../../modules/iam-lambda-role"

  role_name          = "${var.project_name}-lambda-role-dev"
  dynamodb_table_arn = module.dynamodb_table.table_arn
}


module "ses_identity" {
  source = "../../modules/ses-identity"

  email_address = var.notification_email
}

module "contact_form_lambda" {
  source = "../../modules/lambda-function"

  function_name = "${var.project_name}-handler-dev"
  source_dir    = "${path.module}/../../src/lambda"
  role_arn      = module.lambda_role.role_arn

  environment_variables = {
    TABLE_NAME      = module.dynamodb_table.table_name
    SENDER_EMAIL    = module.ses_identity.email_address
    RECIPIENT_EMAIL = module.ses_identity.email_address
  }

  tags = { Environment = "dev" }
}


module "api_gateway" {
  source = "../../modules/api-gateway-http"

  api_name             = "${var.project_name}-api-dev"
  lambda_invoke_arn    = module.contact_form_lambda.invoke_arn
  lambda_function_name = module.contact_form_lambda.function_name
  cors_allow_origin    = "*" # dev only — see docs/adr/0005
}

module "frontend_site" {
  source = "../../modules/s3-static-site"

  bucket_name    = "${var.project_name}-site-dev-${var.site_bucket_suffix}"
  api_invoke_url = "${module.api_gateway.invoke_url}/contact"

  tags = { Environment = "dev" }
}