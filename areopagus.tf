data "aws_organizations_organization" "current" {}

locals {
  areopagus_workload_account_id = one([
    for account in data.aws_organizations_organization.current.non_master_accounts : account.id
    if account.name == var.areopagus_workload_account_name && account.state == "ACTIVE"
  ])
}

provider "aws" {
  alias  = "areopagus_workload"
  region = var.aws_region

  assume_role {
    role_arn = "arn:${data.aws_partition.current.partition}:iam::${local.areopagus_workload_account_id}:role/${var.areopagus_workload_bootstrap_role_name}"
  }

  default_tags {
    tags = var.tags
  }
}

resource "aws_iam_openid_connect_provider" "areopagus_github_actions" {
  provider       = aws.areopagus_workload
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "areopagus_github_actions_assume_deployment" {
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
      values   = [var.areopagus_github_oidc_subject]
    }
  }
}

resource "aws_iam_role" "areopagus_deployment" {
  provider           = aws.areopagus_workload
  name               = var.areopagus_deployment_role_name
  assume_role_policy = data.aws_iam_policy_document.areopagus_github_actions_assume_deployment.json

  tags = var.tags
}

data "aws_iam_policy_document" "areopagus_deployment_assume_state" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.areopagus_terraform_state.arn]
  }
}

resource "aws_iam_role_policy" "areopagus_deployment_assume_state" {
  provider = aws.areopagus_workload
  name     = "assume-areopagus-terraform-state-role"
  role     = aws_iam_role.areopagus_deployment.id
  policy   = data.aws_iam_policy_document.areopagus_deployment_assume_state.json
}

data "aws_iam_policy_document" "areopagus_terraform_state_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.areopagus_deployment.arn]
    }
  }

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values = [
        "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/*AWSReservedSSO_AdministratorAccess_*",
      ]
    }
  }
}

resource "aws_iam_role" "areopagus_terraform_state" {
  name               = var.areopagus_terraform_state_role_name
  assume_role_policy = data.aws_iam_policy_document.areopagus_terraform_state_assume_role.json

  tags = var.tags
}

data "aws_iam_policy_document" "areopagus_terraform_state_access" {
  # Preserve state isolation even if a future bucket policy grants this role
  # broader access than intended.
  statement {
    sid       = "DenyPlatformStateAccess"
    effect    = "Deny"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.terraform_state.arn}/aws-platform/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.terraform_state.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${var.areopagus_terraform_state_key_prefix}/*"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.terraform_state.arn}/${var.areopagus_terraform_state_key_prefix}/*"]
  }
}

resource "aws_iam_role_policy" "areopagus_terraform_state_access" {
  name   = "areopagus-terraform-state-s3-access"
  role   = aws_iam_role.areopagus_terraform_state.id
  policy = data.aws_iam_policy_document.areopagus_terraform_state_access.json
}
