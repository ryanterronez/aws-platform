data "aws_organizations_organization" "current" {}

locals {
  areopagus_workload_account_id = one([
    for account in data.aws_organizations_organization.current.accounts : account.id
    if account.name == "Areopagus" && account.state == "ACTIVE"
  ])
}

resource "aws_iam_openid_connect_provider" "areopagus_github_actions" {
  provider = aws.areopagus

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "areopagus_github_actions_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.areopagus_github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:ryanterronez@48932656/areopagus@${github_repository.areopagus.repo_id}:pull_request",
        "repo:ryanterronez@48932656/areopagus@${github_repository.areopagus.repo_id}:ref:refs/heads/main",
      ]
    }
  }
}

resource "aws_iam_role" "areopagus_github_actions" {
  provider = aws.areopagus

  name               = "areopagus-github-actions"
  assume_role_policy = data.aws_iam_policy_document.areopagus_github_actions_assume_role.json

  tags = var.tags
}

data "aws_iam_policy_document" "areopagus_github_actions" {
  statement {
    sid    = "ManageAreopagusApplicationS3"
    effect = "Allow"
    actions = ["s3:*"]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::areopagus-app-*",
      "arn:${data.aws_partition.current.partition}:s3:::areopagus-app-*/*",
    ]
  }

  statement {
    sid       = "ListS3BucketsForTerraformRefresh"
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }

  statement {
    sid    = "ManageAreopagusDynamoDb"
    effect = "Allow"
    actions = ["dynamodb:*"]
    resources = [
      "arn:${data.aws_partition.current.partition}:dynamodb:${var.aws_region}:${local.areopagus_workload_account_id}:table/areopagus-*",
      "arn:${data.aws_partition.current.partition}:dynamodb:${var.aws_region}:${local.areopagus_workload_account_id}:table/areopagus-*/index/*",
    ]
  }

  statement {
    sid    = "ManageAreopagusLambda"
    effect = "Allow"
    actions = ["lambda:*"]
    resources = ["arn:${data.aws_partition.current.partition}:lambda:${var.aws_region}:${local.areopagus_workload_account_id}:function:areopagus-*"]
  }

  statement {
    sid    = "ManageAreopagusApiGateway"
    effect = "Allow"
    actions = ["apigateway:*"]
    resources = ["arn:${data.aws_partition.current.partition}:apigateway:${var.aws_region}::/restapis/*"]
  }

  statement {
    sid    = "ManageAreopagusEventBridge"
    effect = "Allow"
    actions = ["events:*"]
    resources = [
      "arn:${data.aws_partition.current.partition}:events:${var.aws_region}:${local.areopagus_workload_account_id}:event-bus/areopagus-*",
      "arn:${data.aws_partition.current.partition}:events:${var.aws_region}:${local.areopagus_workload_account_id}:rule/areopagus-*",
    ]
  }

  statement {
    sid    = "ManageAreopagusAlarms"
    effect = "Allow"
    actions = [
      "cloudwatch:DeleteAlarms",
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:SetAlarmState",
      "cloudwatch:TagResource",
      "cloudwatch:UntagResource",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:cloudwatch:${var.aws_region}:${local.areopagus_workload_account_id}:alarm:areopagus-*",
    ]
  }

  statement {
    sid    = "ReadCloudWatchForTerraformRefresh"
    effect = "Allow"
    actions = [
      "cloudwatch:DescribeAlarms",
      "cloudwatch:Get*",
      "cloudwatch:List*",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "ManageAreopagusLogs"
    effect    = "Allow"
    actions   = ["logs:*"]
    resources = [
      "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${local.areopagus_workload_account_id}:log-group:/aws/lambda/areopagus-*",
      "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${local.areopagus_workload_account_id}:log-group:/aws/lambda/areopagus-*:*",
    ]
  }

  statement {
    sid    = "ManageAreopagusTranscribe"
    effect = "Allow"
    actions = ["transcribe:*"]
    resources = ["*"]
  }

  statement {
    sid    = "ManageAreopagusSecrets"
    effect = "Allow"
    actions = ["secretsmanager:*"]
    resources = ["arn:${data.aws_partition.current.partition}:secretsmanager:${var.aws_region}:${local.areopagus_workload_account_id}:secret:areopagus/*"]
  }

  statement {
    sid    = "ManageAreopagusApplicationIam"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateRole",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:iam::${local.areopagus_workload_account_id}:role/areopagus/*"]
  }

  statement {
    sid       = "PassAreopagusApplicationRoles"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:${data.aws_partition.current.partition}:iam::${local.areopagus_workload_account_id}:role/areopagus/*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values = [
        "apigateway.amazonaws.com",
        "events.amazonaws.com",
        "lambda.amazonaws.com",
        "transcribe.amazonaws.com",
      ]
    }
  }

  statement {
    sid    = "AttachAreopagusApplicationPolicies"
    effect = "Allow"
    actions = [
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:iam::${local.areopagus_workload_account_id}:role/areopagus/*"]

    condition {
      test     = "ArnLike"
      variable = "iam:PolicyARN"
      values   = ["arn:${data.aws_partition.current.partition}:iam::${local.areopagus_workload_account_id}:policy/areopagus/*"]
    }
  }

  statement {
    sid    = "ManageAreopagusApplicationPolicies"
    effect = "Allow"
    actions = [
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion",
      "iam:TagPolicy",
      "iam:UntagPolicy",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:iam::${local.areopagus_workload_account_id}:policy/areopagus/*"]
  }

  statement {
    sid    = "ReadOrganizationIdentityForTerraform"
    effect = "Allow"
    actions = [
      "iam:GetAccountAuthorizationDetails",
      "iam:GetAccountSummary",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ListAreopagusTerraformState"
    effect = "Allow"
    actions = ["s3:ListBucket"]
    resources = [aws_s3_bucket.terraform_state.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        "areopagus/terraform.tfstate",
        "areopagus/terraform.tfstate.tflock",
      ]
    }
  }

  statement {
    sid    = "AccessAreopagusTerraformStateObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      "${aws_s3_bucket.terraform_state.arn}/areopagus/terraform.tfstate",
      "${aws_s3_bucket.terraform_state.arn}/areopagus/terraform.tfstate.tflock",
    ]
  }
}

resource "aws_iam_role_policy" "areopagus_github_actions" {
  provider = aws.areopagus

  name   = "areopagus-terraform"
  role   = aws_iam_role.areopagus_github_actions.id
  policy = data.aws_iam_policy_document.areopagus_github_actions.json
}
