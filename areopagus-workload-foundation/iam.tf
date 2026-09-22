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
      "apigateway:*", "dynamodb:*", "lambda:*", "logs:*", "s3:*",
      "secretsmanager:*", "transcribe:*",
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
  statement {
    sid = "ManageApplicationBuckets"
    actions = [
      "s3:CreateBucket", "s3:DeleteBucket", "s3:GetBucketAcl", "s3:GetBucketCORS",
      "s3:GetBucketLocation", "s3:GetBucketLogging", "s3:GetBucketOwnershipControls",
      "s3:GetBucketPolicy", "s3:GetBucketPolicyStatus", "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketTagging", "s3:GetBucketVersioning", "s3:GetEncryptionConfiguration",
      "s3:ListBucket", "s3:PutBucketCORS", "s3:PutBucketLogging",
      "s3:PutBucketOwnershipControls", "s3:PutBucketPolicy", "s3:PutBucketPublicAccessBlock",
      "s3:PutBucketTagging", "s3:PutBucketVersioning", "s3:PutEncryptionConfiguration",
    ]
    resources = [local.application_bucket_arn]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values   = [local.areopagus_workload_account_id]
    }
  }

  statement {
    sid       = "ManageApplicationObjects"
    actions   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
    resources = [local.application_object_arn]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values   = [local.areopagus_workload_account_id]
    }
  }

  statement {
    sid       = "ListBuckets"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }

  statement {
    sid = "ManageApplicationDynamoDb"
    actions = [
      "dynamodb:CreateTable", "dynamodb:DeleteTable", "dynamodb:DescribeContinuousBackups",
      "dynamodb:DescribeContributorInsights", "dynamodb:DescribeKinesisStreamingDestination",
      "dynamodb:DescribeTable", "dynamodb:DescribeTableReplicaAutoScaling",
      "dynamodb:DescribeTimeToLive", "dynamodb:ListTagsOfResource", "dynamodb:TagResource",
      "dynamodb:UntagResource", "dynamodb:UpdateContinuousBackups",
      "dynamodb:UpdateContributorInsights", "dynamodb:UpdateTable",
      "dynamodb:UpdateTableReplicaAutoScaling", "dynamodb:UpdateTimeToLive",
    ]
    resources = [local.application_dynamodb_arn]
  }

  statement {
    sid       = "ListDynamoDbTables"
    actions   = ["dynamodb:ListTables"]
    resources = ["*"]
  }

  statement {
    sid = "ManageApplicationLambda"
    actions = [
      "lambda:AddPermission", "lambda:CreateAlias", "lambda:CreateFunction", "lambda:DeleteAlias",
      "lambda:DeleteFunction", "lambda:GetAlias", "lambda:GetFunction",
      "lambda:GetFunctionCodeSigningConfig", "lambda:GetFunctionConfiguration", "lambda:GetPolicy",
      "lambda:ListAliases", "lambda:ListTags", "lambda:PublishVersion", "lambda:RemovePermission",
      "lambda:TagResource", "lambda:UntagResource", "lambda:UpdateAlias",
      "lambda:UpdateFunctionCode", "lambda:UpdateFunctionConfiguration",
    ]
    resources = [local.application_lambda_arn]
  }

  statement {
    sid = "ManageLambdaEventSources"
    actions = [
      "lambda:CreateEventSourceMapping", "lambda:DeleteEventSourceMapping",
      "lambda:GetEventSourceMapping", "lambda:ListEventSourceMappings",
      "lambda:UpdateEventSourceMapping",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "ManageApiGateway"
    actions   = ["apigateway:DELETE", "apigateway:GET", "apigateway:PATCH", "apigateway:POST", "apigateway:PUT"]
    resources = ["*"]
  }

  statement {
    sid = "ManageApplicationLogGroups"
    actions = [
      "logs:CreateLogGroup", "logs:DeleteLogGroup", "logs:DescribeLogGroups",
      "logs:ListTagsForResource", "logs:PutRetentionPolicy", "logs:TagResource", "logs:UntagResource",
    ]
    resources = [local.application_log_group_arn]
  }

  statement {
    sid = "ManageApplicationSecrets"
    actions = [
      "secretsmanager:CreateSecret", "secretsmanager:DeleteSecret", "secretsmanager:DescribeSecret",
      "secretsmanager:GetResourcePolicy", "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecretVersionIds", "secretsmanager:PutResourcePolicy",
      "secretsmanager:PutSecretValue", "secretsmanager:RestoreSecret", "secretsmanager:TagResource",
      "secretsmanager:UntagResource", "secretsmanager:UpdateSecret",
      "secretsmanager:UpdateSecretVersionStage",
    ]
    resources = [local.application_secret_arn]
  }

  statement {
    sid       = "ListSecrets"
    actions   = ["secretsmanager:ListSecrets"]
    resources = ["*"]
  }

  statement {
    sid = "ManageTranscriptionJobs"
    actions = [
      "transcribe:DeleteTranscriptionJob", "transcribe:GetTranscriptionJob",
      "transcribe:ListTagsForResource", "transcribe:ListTranscriptionJobs",
      "transcribe:StartTranscriptionJob", "transcribe:TagResource", "transcribe:UntagResource",
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
    resources = [local.application_role_arn]
  }

  statement {
    sid       = "CreateBoundedApplicationRoles"
    actions   = ["iam:CreateRole", "iam:PutRolePermissionsBoundary"]
    resources = [local.application_role_arn]

    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values   = [aws_iam_policy.application_boundary.arn]
    }
  }

  statement {
    sid       = "PassApplicationRoles"
    actions   = ["iam:PassRole"]
    resources = [local.application_role_arn]
  }

  statement {
    sid       = "TerraformIdentity"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }

  statement {
    sid       = "ListTerraformState"
    actions   = ["s3:ListBucket"]
    resources = [local.terraform_state_bucket_arn]

    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values = [
        var.areopagus_terraform_state_key,
        "${var.areopagus_terraform_state_key}.tflock",
      ]
    }
  }

  statement {
    sid       = "ReadWriteTerraformState"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = [local.terraform_state_object_arn]
  }

  statement {
    sid       = "ManageTerraformLock"
    actions   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
    resources = [local.terraform_state_lock_arn]
  }
}

resource "aws_iam_policy" "deployment_access" {
  provider    = aws.areopagus_workload
  name        = "AreopagusTerraformApplicationDeployment"
  path        = local.guardrail_iam_path
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
    sid = "ReadApplicationBuckets"
    actions = [
      "s3:GetBucketAcl", "s3:GetBucketCORS", "s3:GetBucketLocation", "s3:GetBucketLogging",
      "s3:GetBucketOwnershipControls", "s3:GetBucketPolicy", "s3:GetBucketPolicyStatus",
      "s3:GetBucketPublicAccessBlock", "s3:GetBucketTagging", "s3:GetBucketVersioning",
      "s3:GetEncryptionConfiguration", "s3:GetObject", "s3:ListBucket",
    ]
    resources = [local.application_bucket_arn, local.application_object_arn]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values   = [local.areopagus_workload_account_id]
    }
  }

  statement {
    sid       = "ListBuckets"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }

  statement {
    sid = "ReadApplicationDynamoDb"
    actions = [
      "dynamodb:DescribeContinuousBackups", "dynamodb:DescribeContributorInsights",
      "dynamodb:DescribeKinesisStreamingDestination", "dynamodb:DescribeTable",
      "dynamodb:DescribeTableReplicaAutoScaling", "dynamodb:DescribeTimeToLive",
      "dynamodb:ListTagsOfResource",
    ]
    resources = [local.application_dynamodb_arn]
  }

  statement {
    sid       = "ListDynamoDbTables"
    actions   = ["dynamodb:ListTables"]
    resources = ["*"]
  }

  statement {
    sid = "ReadApplicationLambda"
    actions = [
      "lambda:GetAlias", "lambda:GetFunction", "lambda:GetFunctionCodeSigningConfig",
      "lambda:GetFunctionConfiguration", "lambda:GetPolicy", "lambda:ListAliases", "lambda:ListTags",
    ]
    resources = [local.application_lambda_arn]
  }

  statement {
    sid       = "ReadLambdaEventSources"
    actions   = ["lambda:GetEventSourceMapping", "lambda:ListEventSourceMappings"]
    resources = ["*"]
  }

  statement {
    sid       = "ReadApiGateway"
    actions   = ["apigateway:GET"]
    resources = ["*"]
  }

  statement {
    sid       = "ReadApplicationLogs"
    actions   = ["logs:DescribeLogGroups", "logs:ListTagsForResource"]
    resources = [local.application_log_group_arn]
  }

  statement {
    sid = "ReadApplicationSecrets"
    actions = [
      "secretsmanager:DescribeSecret", "secretsmanager:GetResourcePolicy",
      "secretsmanager:ListSecretVersionIds",
    ]
    resources = [local.application_secret_arn]
  }

  statement {
    sid       = "ListSecrets"
    actions   = ["secretsmanager:ListSecrets"]
    resources = ["*"]
  }

  statement {
    sid = "ReadTranscriptionJobs"
    actions = [
      "transcribe:GetTranscriptionJob", "transcribe:ListTagsForResource", "transcribe:ListTranscriptionJobs",
    ]
    resources = ["*"]
  }

  statement {
    sid = "ReadApplicationRoles"
    actions = [
      "iam:GetRole", "iam:GetRolePolicy", "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole", "iam:ListRolePolicies", "iam:ListRoleTags",
    ]
    resources = [local.application_role_arn]
  }

  statement {
    sid       = "TerraformIdentity"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }

  statement {
    sid       = "ListTerraformState"
    actions   = ["s3:ListBucket"]
    resources = [local.terraform_state_bucket_arn]

    condition {
      test     = "StringEquals"
      variable = "s3:prefix"
      values = [
        var.areopagus_terraform_state_key,
        "${var.areopagus_terraform_state_key}.tflock",
      ]
    }
  }

  statement {
    sid       = "ReadTerraformState"
    actions   = ["s3:GetObject"]
    resources = [local.terraform_state_object_arn]
  }

  statement {
    sid       = "ManageTerraformLock"
    actions   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
    resources = [local.terraform_state_lock_arn]
  }
}

resource "aws_iam_policy" "plan_access" {
  provider    = aws.areopagus_workload
  name        = "AreopagusTerraformApplicationPlan"
  path        = local.guardrail_iam_path
  description = "Read-only Areopagus discovery and Terraform state access for pull-request plans."
  policy      = data.aws_iam_policy_document.plan_access.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "plan_access" {
  provider   = aws.areopagus_workload
  role       = aws_iam_role.plan.name
  policy_arn = aws_iam_policy.plan_access.arn
}
