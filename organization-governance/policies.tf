data "aws_iam_policy_document" "account_departure_protection" {
  statement {
    sid    = "DenyMemberAccountDepartureOrClosure"
    effect = "Deny"
    actions = [
      "account:CloseAccount",
      "organizations:LeaveOrganization",
    ]
    resources = ["*"]
  }
}

resource "aws_organizations_policy" "scp_account_protection" {
  count = var.existing_account_departure_protection_policy_id == null ? 1 : 0

  name        = "scp_account_protection"
  description = "Prevents workload accounts from leaving the organization or closing themselves."
  content     = data.aws_iam_policy_document.account_departure_protection.json
  type        = "SERVICE_CONTROL_POLICY"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_policy_attachment" "scp_account_protection" {
  count = var.existing_account_departure_protection_policy_id == null ? 1 : 0

  policy_id = aws_organizations_policy.scp_account_protection[0].id
  target_id = aws_organizations_organizational_unit.workloads.id
}

data "aws_iam_policy_document" "identity_guardrails" {
  statement {
    sid    = "DenyLongLivedIamIdentities"
    effect = "Deny"
    actions = [
      "iam:CreateAccessKey",
      "iam:CreateLoginProfile",
      "iam:CreateUser",
    ]
    resources = ["*"]
  }
}

resource "aws_organizations_policy" "scp_identity_guardrails" {
  name        = "scp_identity_guardrails"
  description = "Prevents IAM users, console passwords, and access keys in workload accounts."
  content     = data.aws_iam_policy_document.identity_guardrails.json
  type        = "SERVICE_CONTROL_POLICY"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_policy_attachment" "scp_identity_guardrails" {
  policy_id = aws_organizations_policy.scp_identity_guardrails.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

data "aws_iam_policy_document" "service_allowlist" {
  statement {
    sid    = "DenyUnapprovedServices"
    effect = "Deny"

    not_actions = [
      "apigateway:*",
      "cloudtrail:*",
      "cloudwatch:*",
      "config:*",
      "dynamodb:*",
      "ecr:*",
      "events:*",
      "guardduty:*",
      "iam:*",
      "identitystore:*",
      "kms:*",
      "lambda:*",
      "logs:*",
      "organizations:*",
      "s3:*",
      "secretsmanager:*",
      "securityhub:*",
      "sns:*",
      "sqs:*",
      "ssm:*",
      "sso:*",
      "sso-admin:*",
      "sso-directory:*",
      "sso-oidc:*",
      "states:*",
      "sts:*",
      "transcribe:*",
    ]

    resources = ["*"]
  }
}

resource "aws_organizations_policy" "scp_service_allowlist" {
  name        = "scp_service_allowlist"
  description = "Denies all services except the Areopagus baseline service allowlist."
  content     = data.aws_iam_policy_document.service_allowlist.json
  type        = "SERVICE_CONTROL_POLICY"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_policy_attachment" "scp_service_allowlist" {
  policy_id = aws_organizations_policy.scp_service_allowlist.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

data "aws_iam_policy_document" "resource_perimeter" {
  statement {
    sid    = "DenyAccessOutsideOrganization"
    effect = "Deny"
    actions = [
      "dynamodb:*",
      "ecr:*",
      "events:*",
      "kms:*",
      "logs:*",
      "s3:*",
      "secretsmanager:*",
      "sqs:*",
      "sts:*",
      "transcribe:*",
    ]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalOrgID"
      values   = [data.aws_organizations_organization.current.id]
    }

    condition {
      test     = "Bool"
      variable = "aws:PrincipalIsAWSService"
      values   = ["false"]
    }
  }
}

resource "aws_organizations_policy" "rcp_resource_perimeter" {
  name        = "rcp_resource_perimeter"
  description = "Restricts supported workload resources to Organization principals and AWS services."
  content     = data.aws_iam_policy_document.resource_perimeter.json
  type        = "RESOURCE_CONTROL_POLICY"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_policy_attachment" "rcp_resource_perimeter" {
  policy_id = aws_organizations_policy.rcp_resource_perimeter.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_policy" "organization_policy_ec2" {
  name        = "organization_policy_ec2"
  description = "Workload EC2 baseline: no new public AMI or snapshot sharing, IMDSv2 required, and serial console disabled."
  content = jsonencode({
    ec2_attributes = {
      image_block_public_access = {
        state = { "@@assign" = "block_new_sharing" }
      }
      snapshot_block_public_access = {
        state = { "@@assign" = "block_all_sharing" }
      }
      instance_metadata_defaults = {
        http_put_response_hop_limit = { "@@assign" = -1 }
        http_endpoint               = { "@@assign" = "no_preference" }
        instance_metadata_tags      = { "@@assign" = "no_preference" }
        http_tokens                 = { "@@assign" = "required" }
        http_tokens_enforced        = { "@@assign" = "enabled" }
      }
      serial_console_access = {
        status = { "@@assign" = "disabled" }
      }
    }
  })
  type = "DECLARATIVE_POLICY_EC2"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_policy_attachment" "organization_policy_ec2" {
  policy_id = aws_organizations_policy.organization_policy_ec2.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_policy" "organization_policy_s3" {
  name        = "organization_policy_s3"
  description = "Enforces all four S3 Block Public Access settings for workload accounts."
  content = jsonencode({
    s3_attributes = {
      public_access_block_configuration = { "@@assign" = "all" }
    }
  })
  type = "S3_POLICY"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_policy_attachment" "organization_policy_s3" {
  policy_id = aws_organizations_policy.organization_policy_s3.id
  target_id = aws_organizations_organizational_unit.workloads.id
}
