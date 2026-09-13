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
    sid    = "S3ProjectResourcesOnly"
    effect = "Allow"
    actions = [
      "s3:CreateBucket", "s3:DeleteBucket", "s3:GetObject", "s3:PutObject",
      "s3:DeleteObject", "s3:ListBucket", "s3:PutBucketPolicy", "s3:GetBucketPolicy",
      "s3:PutBucketVersioning", "s3:GetBucketVersioning", "s3:PutEncryptionConfiguration",
      "s3:GetEncryptionConfiguration", "s3:PutBucketPublicAccessBlock",
      "s3:GetBucketPublicAccessBlock", "s3:PutBucketWebsite", "s3:GetBucketWebsite"
    ]
    resources = [
      "arn:aws:s3:::${var.project_name}-*",
      "arn:aws:s3:::${var.project_name}-*/*"
    ]
  }

  statement {
    sid       = "DynamoDBProjectTableOnly"
    effect    = "Allow"
    actions   = ["dynamodb:CreateTable", "dynamodb:DeleteTable", "dynamodb:DescribeTable", "dynamodb:UpdateTable", "dynamodb:TagResource"]
    resources = ["arn:aws:dynamodb:*:*:table/${var.project_name}-*"]
  }

  statement {
    sid       = "LambdaProjectFunctionOnly"
    effect    = "Allow"
    actions   = ["lambda:CreateFunction", "lambda:DeleteFunction", "lambda:GetFunction", "lambda:UpdateFunctionCode", "lambda:UpdateFunctionConfiguration", "lambda:AddPermission", "lambda:RemovePermission", "lambda:GetPolicy", "lambda:TagResource"]
    resources = ["arn:aws:lambda:*:*:function:${var.project_name}-*"]
  }

  statement {
    sid       = "IAMProjectRoleOnly"
    effect    = "Allow"
    actions   = ["iam:GetRole", "iam:CreateRole", "iam:DeleteRole", "iam:TagRole", "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:GetRolePolicy", "iam:AttachRolePolicy", "iam:DetachRolePolicy", "iam:ListRolePolicies", "iam:ListAttachedRolePolicies", "iam:PassRole"]
    resources = ["arn:aws:iam::*:role/${var.project_name}-*"]
  }

  statement {
    sid       = "SNSProjectTopicOnly"
    effect    = "Allow"
    actions   = ["sns:CreateTopic", "sns:DeleteTopic", "sns:Subscribe", "sns:GetTopicAttributes", "sns:SetTopicAttributes"]
    resources = ["arn:aws:sns:*:*:${var.project_name}-*"]
  }


  statement {
    sid       = "ApiGatewayBroaderByNecessity"
    effect    = "Allow"
    actions   = ["apigateway:*"]
    resources = ["arn:aws:apigateway:*::/apis", "arn:aws:apigateway:*::/apis/*"]
  }

  statement {
    sid       = "SESBroaderByNecessity"
    effect    = "Allow"
    actions   = ["ses:VerifyEmailIdentity", "ses:DeleteIdentity", "ses:GetIdentityVerificationAttributes"]
    resources = ["*"]
  }

  statement {
    sid       = "CloudWatchLogsAndAlarms"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:DeleteLogGroup", "logs:PutRetentionPolicy", "logs:DescribeLogGroups", "cloudwatch:PutMetricAlarm", "cloudwatch:DeleteAlarms", "cloudwatch:DescribeAlarms"]
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