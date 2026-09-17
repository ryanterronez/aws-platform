data "aws_organizations_organization" "current" {}

locals {
  areopagus_workload_account_id = one([
    for account in data.aws_organizations_organization.current.non_master_accounts : account.id
    if account.name == var.areopagus_workload_account_name && account.state == "ACTIVE"
  ])

  areopagus_deployment_role_arn = "arn:${data.aws_partition.current.partition}:iam::${local.areopagus_workload_account_id}:role/${var.areopagus_deployment_role_name}"
}

data "aws_iam_policy_document" "areopagus_terraform_state_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [local.areopagus_deployment_role_arn]
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
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [
      "${aws_s3_bucket.terraform_state.arn}/${var.areopagus_terraform_state_key_prefix}/*",
    ]
  }
}

resource "aws_iam_role_policy" "areopagus_terraform_state_access" {
  name   = "areopagus-terraform-state-s3-access"
  role   = aws_iam_role.areopagus_terraform_state.id
  policy = data.aws_iam_policy_document.areopagus_terraform_state_access.json
}
