data "aws_organizations_organization" "current" {}

data "aws_partition" "current" {}

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
