resource "aws_iam_role" "deployment" {
  provider           = aws.areopagus_workload
  name               = "areopagus-github-actions-deployment"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_deployment.json
  tags               = var.tags
}

data "aws_iam_policy_document" "application_boundary" {
  statement {
    effect = "Allow"
    actions = [
      "apigateway:*", "dynamodb:*", "events:*", "lambda:*", "logs:*", "s3:*",
      "secretsmanager:*", "transcribe:*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "application_boundary" {
  provider    = aws.areopagus_workload
  name        = "AreopagusApplicationPermissionsBoundary"
  path        = "/areopagus/guardrails/"
  description = "Maximum permissions for Terraform-managed Areopagus application roles."
  policy      = data.aws_iam_policy_document.application_boundary.json

  lifecycle {
    prevent_destroy = true
  }

  tags = var.tags
}

data "aws_iam_policy_document" "deployment_access" {
  statement {
    sid       = "ManageApplicationS3"
    actions   = ["s3:*"]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::areopagus-*",
      "arn:${data.aws_partition.current.partition}:s3:::areopagus-*/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values   = [local.areopagus_workload_account_id]
    }
  }

  statement {
    sid       = "ManageApplicationDynamoDb"
    actions   = ["dynamodb:*"]
    resources = [
      "arn:${data.aws_partition.current.partition}:dynamodb:${var.aws_region}:${local.areopagus_workload_account_id}:table/areopagus-*",
      "arn:${data.aws_partition.current.partition}:dynamodb:${var.aws_region}:${local.areopagus_workload_account_id}:table/areopagus-*/index/*",
    ]
  }

  statement {
    sid       = "ManageApplicationLambda"
    actions   = ["lambda:*"]
    resources = ["arn:${data.aws_partition.current.partition}:lambda:${var.aws_region}:${local.areopagus_workload_account_id}:function:areopagus-*"]
  }

  statement {
    sid       = "ManageApplicationLogs"
    actions   = ["logs:*"]
    resources = ["arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${local.areopagus_workload_account_id}:log-group:/aws/lambda/areopagus-*:*" ]
  }

  statement {
    sid       = "ManageApplicationSecrets"
    actions   = ["secretsmanager:*"]
    resources = ["arn:${data.aws_partition.current.partition}:secretsmanager:${var.aws_region}:${local.areopagus_workload_account_id}:secret:areopagus/*"]
  }

  statement {
    sid       = "ManageApplicationEventBridge"
    actions   = ["events:*"]
    resources = ["arn:${data.aws_partition.current.partition}:events:${var.aws_region}:${local.areopagus_workload_account_id}:*/*areopagus-*"]
  }

  # These service APIs do not offer sufficiently useful resource-level IAM
  # scoping for their Terraform control-plane operations.
  statement {
    sid       = "ManageApiGatewayAndTranscribe"
    actions   = ["apigateway:*", "transcribe:*"]
    resources = ["*"]
  }

  statement {
    sid = "DiscoverApplicationResources"
    actions = [
      "dynamodb:ListTables", "lambda:ListEventSourceMappings", "lambda:ListFunctions",
      "logs:DescribeLogGroups", "secretsmanager:ListSecrets",
    ]
    resources = ["*"]
  }

  statement {
    sid = "ManageApplicationRoles"
    actions = [
      "iam:DeleteRole", "iam:DeleteRolePolicy", "iam:GetRole", "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies", "iam:ListInstanceProfilesForRole", "iam:ListRolePolicies",
      "iam:ListRoleTags", "iam:PutRolePermissionsBoundary", "iam:PutRolePolicy", "iam:TagRole",
      "iam:UntagRole", "iam:UpdateAssumeRolePolicy", "iam:UpdateRole",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:iam::${local.areopagus_workload_account_id}:role/areopagus/application/*"]
  }

  statement {
    sid       = "CreateBoundedApplicationRoles"
    actions   = ["iam:CreateRole", "iam:PutRolePermissionsBoundary"]
    resources = ["arn:${data.aws_partition.current.partition}:iam::${local.areopagus_workload_account_id}:role/areopagus/application/*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values   = [aws_iam_policy.application_boundary.arn]
    }
  }

  statement {
    sid       = "PassApplicationRoles"
    actions   = ["iam:PassRole"]
    resources = ["arn:${data.aws_partition.current.partition}:iam::${local.areopagus_workload_account_id}:role/areopagus/application/*"]
  }

  statement {
    sid       = "TerraformIdentity"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }

  statement {
    sid       = "ListTerraformState"
    actions   = ["s3:ListBucket"]
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${var.terraform_state_bucket_name}"]

    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values   = [var.areopagus_terraform_state_key, "${var.areopagus_terraform_state_key}.tflock"]
    }
  }

  statement {
    sid       = "ReadWriteTerraformState"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${var.terraform_state_bucket_name}/${var.areopagus_terraform_state_key}"]
  }

  statement {
    sid       = "ManageTerraformLock"
    actions   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${var.terraform_state_bucket_name}/${var.areopagus_terraform_state_key}.tflock"]
  }
}

resource "aws_iam_policy" "deployment_access" {
  provider    = aws.areopagus_workload
  name        = "AreopagusTerraformApplicationDeployment"
  path        = "/areopagus/guardrails/"
  description = "Areopagus application infrastructure and direct Terraform state access."
  policy      = data.aws_iam_policy_document.deployment_access.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "deployment_access" {
  provider   = aws.areopagus_workload
  role       = aws_iam_role.deployment.name
  policy_arn = aws_iam_policy.deployment_access.arn
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
  tags               = var.tags
}

data "aws_iam_policy_document" "plan_access" {
  statement {
    sid       = "ReadApplicationS3"
    actions   = ["s3:Get*", "s3:List*"]
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::areopagus-*",
      "arn:${data.aws_partition.current.partition}:s3:::areopagus-*/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values   = [local.areopagus_workload_account_id]
    }
  }

  statement {
    sid       = "ReadApplicationDynamoDb"
    actions   = ["dynamodb:Describe*", "dynamodb:List*"]
    resources = [
      "arn:${data.aws_partition.current.partition}:dynamodb:${var.aws_region}:${local.areopagus_workload_account_id}:table/areopagus-*",
      "arn:${data.aws_partition.current.partition}:dynamodb:${var.aws_region}:${local.areopagus_workload_account_id}:table/areopagus-*/index/*",
    ]
  }

  statement {
    sid       = "ReadApplicationLambda"
    actions   = ["lambda:Get*", "lambda:List*"]
    resources = ["arn:${data.aws_partition.current.partition}:lambda:${var.aws_region}:${local.areopagus_workload_account_id}:function:areopagus-*"]
  }

  statement {
    sid       = "ReadApplicationLogs"
    actions   = ["logs:Describe*", "logs:List*"]
    resources = ["arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${local.areopagus_workload_account_id}:log-group:/aws/lambda/areopagus-*:*" ]
  }

  statement {
    sid       = "ReadApplicationSecrets"
    actions   = ["secretsmanager:Describe*", "secretsmanager:List*"]
    resources = ["arn:${data.aws_partition.current.partition}:secretsmanager:${var.aws_region}:${local.areopagus_workload_account_id}:secret:areopagus/*"]
  }

  statement {
    sid       = "ReadApplicationEventBridge"
    actions   = ["events:Describe*", "events:List*"]
    resources = ["arn:${data.aws_partition.current.partition}:events:${var.aws_region}:${local.areopagus_workload_account_id}:*/*areopagus-*"]
  }

  statement {
    sid       = "ReadApiGatewayAndTranscribe"
    actions   = ["apigateway:GET", "transcribe:Get*", "transcribe:List*"]
    resources = ["*"]
  }

  statement {
    sid = "DiscoverApplicationResources"
    actions = [
      "dynamodb:ListTables", "lambda:ListEventSourceMappings", "lambda:ListFunctions",
      "logs:DescribeLogGroups", "secretsmanager:ListSecrets",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "ReadApplicationRoles"
    actions   = ["iam:GetRole", "iam:GetRolePolicy", "iam:ListAttachedRolePolicies", "iam:ListInstanceProfilesForRole", "iam:ListRolePolicies", "iam:ListRoleTags"]
    resources = ["arn:${data.aws_partition.current.partition}:iam::${local.areopagus_workload_account_id}:role/areopagus/application/*"]
  }

  statement {
    sid       = "TerraformIdentity"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }

  statement {
    sid       = "ListTerraformState"
    actions   = ["s3:ListBucket"]
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${var.terraform_state_bucket_name}"]

    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values   = [var.areopagus_terraform_state_key, "${var.areopagus_terraform_state_key}.tflock"]
    }
  }

  statement {
    sid       = "ReadTerraformState"
    actions   = ["s3:GetObject"]
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${var.terraform_state_bucket_name}/${var.areopagus_terraform_state_key}"]
  }

  statement {
    sid       = "ManageTerraformLock"
    actions   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
    resources = ["arn:${data.aws_partition.current.partition}:s3:::${var.terraform_state_bucket_name}/${var.areopagus_terraform_state_key}.tflock"]
  }
}

resource "aws_iam_policy" "plan_access" {
  provider    = aws.areopagus_workload
  name        = "AreopagusTerraformApplicationPlan"
  path        = "/areopagus/guardrails/"
  description = "Read-only Areopagus discovery and Terraform state access for pull-request plans."
  policy      = data.aws_iam_policy_document.plan_access.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "plan_access" {
  provider   = aws.areopagus_workload
  role       = aws_iam_role.plan.name
  policy_arn = aws_iam_policy.plan_access.arn
}
