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