data "aws_organizations_organization" "current" {}

data "aws_partition" "current" {}

locals {
  areopagus_workload_account_id = one([
    for account in data.aws_organizations_organization.current.non_master_accounts : account.id
    if account.name == var.areopagus_workload_account_name && account.state == "ACTIVE"
  ])

  application_iam_path = "/areopagus/application/"
  guardrail_iam_path   = "/areopagus/guardrails/"

  application_role_arn = "arn:${data.aws_partition.current.partition}:iam::${local.areopagus_workload_account_id}:role${local.application_iam_path}*"
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

resource "aws_iam_openid_connect_provider" "github_actions" {
  provider       = aws.areopagus_workload
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "github_actions_assume_deployment" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
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

resource "aws_iam_role" "deployment" {
  provider           = aws.areopagus_workload
  name               = var.areopagus_deployment_role_name
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_deployment.json

  tags = var.tags
}

data "aws_iam_policy_document" "application_boundary" {
  # The Workloads SCP is the authoritative service allowlist. This boundary
  # prevents application roles from becoming IAM, Organizations, Identity
  # Center, or STS administrators within that account-level limit.
  statement {
    effect = "Allow"
    not_actions = [
      "iam:*",
      "identitystore:*",
      "organizations:*",
      "sso:*",
      "sso-admin:*",
      "sso-directory:*",
      "sso-oidc:*",
      "sts:*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "application_boundary" {
  provider    = aws.areopagus_workload
  name        = "AreopagusApplicationPermissionsBoundary"
  path        = local.guardrail_iam_path
  description = "Maximum permissions for Terraform-managed Areopagus application roles."
  policy      = data.aws_iam_policy_document.application_boundary.json

  lifecycle {
    prevent_destroy = true
  }

  tags = var.tags
}

data "aws_iam_policy_document" "deployment_access" {
  # SCPs constrain this broad application-service allow to the Workloads
  # service allowlist. Identity, Organization, and arbitrary STS access are
  # granted only by the following narrowly scoped statements.
  statement {
    effect = "Allow"
    not_actions = [
      "iam:*",
      "identitystore:*",
      "organizations:*",
      "sso:*",
      "sso-admin:*",
      "sso-directory:*",
      "sso-oidc:*",
      "sts:*",
    ]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:DeleteRole",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:ListRoleTags",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateRole",
    ]
    resources = [local.application_role_arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:PutRolePermissionsBoundary",
    ]
    resources = [local.application_role_arn]

    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values   = [aws_iam_policy.application_boundary.arn]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:DeleteRolePolicy",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:PutRolePolicy",
    ]
    resources = [local.application_role_arn]
  }

  statement {
    effect = "Allow"
    actions   = ["iam:PassRole"]
    resources = [local.application_role_arn]
  }
}

resource "aws_iam_policy" "deployment_access" {
  provider    = aws.areopagus_workload
  name        = "AreopagusTerraformApplicationDeployment"
  path        = local.guardrail_iam_path
  description = "Application infrastructure and bounded IAM permissions for Areopagus Terraform applies."
  policy      = data.aws_iam_policy_document.deployment_access.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "deployment_access" {
  provider   = aws.areopagus_workload
  role       = aws_iam_role.deployment.name
  policy_arn = aws_iam_policy.deployment_access.arn
}

data "aws_iam_policy_document" "deployment_assume_state" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_organizations_organization.current.master_account_id}:role/${var.areopagus_terraform_state_role_name}",
    ]
  }
}

resource "aws_iam_role_policy" "deployment_assume_state" {
  provider = aws.areopagus_workload
  name     = "assume-areopagus-terraform-state-role"
  role     = aws_iam_role.deployment.id
  policy   = data.aws_iam_policy_document.deployment_assume_state.json
}

data "aws_iam_policy_document" "github_actions_assume_plan" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [var.areopagus_github_oidc_plan_subject]
    }
  }
}

resource "aws_iam_role" "plan" {
  provider           = aws.areopagus_workload
  name               = var.areopagus_plan_role_name
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_plan.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "plan_read_only" {
  provider   = aws.areopagus_workload
  role       = aws_iam_role.plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "plan_assume_state" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_organizations_organization.current.master_account_id}:role/${var.areopagus_terraform_plan_state_role_name}",
    ]
  }
}

resource "aws_iam_role_policy" "plan_assume_state" {
  provider = aws.areopagus_workload
  name     = "assume-areopagus-terraform-plan-state-role"
  role     = aws_iam_role.plan.id
  policy   = data.aws_iam_policy_document.plan_assume_state.json
}
