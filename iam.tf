data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

resource "aws_iam_role" "github_actions" {
  name               = var.github_actions_role_name
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = var.tags
}

data "aws_iam_policy_document" "terraform_state_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.github_actions.arn]
    }
  }

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
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

resource "aws_iam_role" "terraform_state" {
  name               = var.terraform_state_role_name
  assume_role_policy = data.aws_iam_policy_document.terraform_state_assume_role.json

  tags = var.tags
}

data "aws_iam_policy_document" "terraform_state_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [aws_s3_bucket.terraform_state.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${var.terraform_state_key_prefix}/*"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.terraform_state.arn}/${var.terraform_state_key_prefix}/*"]
  }
}

resource "aws_iam_role_policy" "terraform_state_access" {
  name   = "terraform-state-s3-access"
  role   = aws_iam_role.terraform_state.id
  policy = data.aws_iam_policy_document.terraform_state_access.json
}

data "aws_iam_policy_document" "github_actions_assume_terraform_state" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.terraform_state.arn]
  }
}

resource "aws_iam_role_policy" "github_actions_assume_terraform_state" {
  name   = "assume-terraform-state-role"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_assume_terraform_state.json
}

data "aws_iam_policy_document" "github_actions_plan_read" {
  statement {
    sid = "ReadTerraformStateBucket"

    actions = [
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
      "s3:GetBucketOwnershipControls",
      "s3:GetBucketPolicy",
      "s3:GetBucketPolicyStatus",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketTagging",
      "s3:GetBucketVersioning",
      "s3:GetEncryptionConfiguration",
      "s3:ListBucket",
    ]

    resources = [aws_s3_bucket.terraform_state.arn]
  }

  statement {
    sid       = "ReadManagedIamRoles"
    actions   = ["iam:GetRole"]
    resources = [aws_iam_role.github_actions.arn, aws_iam_role.terraform_state.arn]
  }

  statement {
    sid       = "ReadManagedInlineRolePolicies"
    actions   = ["iam:GetRolePolicy"]
    resources = [aws_iam_role.github_actions.arn, aws_iam_role.terraform_state.arn]
  }

  statement {
    sid       = "ReadGitHubOidcProvider"
    actions   = ["iam:GetOpenIDConnectProvider"]
    resources = [aws_iam_openid_connect_provider.github_actions.arn]
  }
}

resource "aws_iam_role_policy" "github_actions_plan_read" {
  name   = "terraform-plan-read"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_plan_read.json
}
