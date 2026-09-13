data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

data "aws_iam_policy_document" "github_actions_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

condition {
  test     = "StringLike"
  variable = "token.actions.githubusercontent.com:sub"
  values = [
    "repo:${var.github_repo}:*",
    "repo:${split("/", var.github_repo)[0]}@*/${split("/", var.github_repo)[1]}@*:*"
  ]
}
  }
}

resource "aws_iam_role" "github_actions_deploy" {
  name               = "${var.project_name}-github-actions-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume.json
}

data "aws_iam_policy_document" "github_actions_deploy" {
  statement {
    sid       = "S3ProjectResourcesOnly"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = [
      "arn:aws:s3:::${var.project_name}-*",
      "arn:aws:s3:::${var.project_name}-*/*"
    ]
  }

  statement {
    sid       = "DynamoDBProjectTableOnly"
    effect    = "Allow"
    actions   = ["dynamodb:*"]
    resources = ["arn:aws:dynamodb:*:*:table/${var.project_name}-*"]
  }

  statement {
    sid       = "LambdaProjectFunctionOnly"
    effect    = "Allow"
    actions   = ["lambda:*"]
    resources = ["arn:aws:lambda:*:*:function:${var.project_name}-*"]
  }

  statement {
    sid       = "IAMProjectRoleOnly"
    effect    = "Allow"
    actions   = ["iam:*"]
    resources = ["arn:aws:iam::*:role/${var.project_name}-*"]
  }

  statement {
    sid       = "SNSProjectTopicOnly"
    effect    = "Allow"
    actions   = ["sns:*"]
    resources = ["arn:aws:sns:*:*:${var.project_name}-*"]
  }

  statement {
    sid       = "ApiGatewayBroaderByNecessity"
    effect    = "Allow"
    actions   = ["apigateway:*"]
    resources = ["arn:aws:apigateway:*::/*"]
  }

  statement {
    sid       = "SESBroaderByNecessity"
    effect    = "Allow"
    actions   = ["ses:*"]
    resources = ["*"]
  }

  statement {
    sid       = "CloudWatchLogsAndAlarms"
    effect    = "Allow"
    actions   = ["logs:*", "cloudwatch:*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "github_actions_deploy" {
  name   = "${var.project_name}-github-actions-deploy-policy"
  policy = data.aws_iam_policy_document.github_actions_deploy.json
}

resource "aws_iam_role_policy_attachment" "deploy_permissions" {
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = aws_iam_policy.github_actions_deploy.arn
}