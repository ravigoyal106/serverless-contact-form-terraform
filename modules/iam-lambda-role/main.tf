data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }

}

resource "aws_iam_role" "lambda_execution" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags


}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "contact_form_permissions" {
  statement {
    effect    = "Allow"
    actions   = ["ses:SendEmail"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["dynamodb:PutItem"]
    resources = [var.dynamodb_table_arn]
  }
}

resource "aws_iam_role_policy" "contact_form_permissions" {
  name   = "${var.role_name}-permissions"
  role   = aws_iam_role.lambda_execution.id
  policy = data.aws_iam_policy_document.contact_form_permissions.json
}