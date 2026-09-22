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
  name        = "scp_account_protection"
  description = "Prevents workload accounts from leaving the organization or closing themselves."
  content     = data.aws_iam_policy_document.account_departure_protection.json
  type        = "SERVICE_CONTROL_POLICY"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_policy_attachment" "scp_account_protection" {
  policy_id = aws_organizations_policy.scp_account_protection.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

moved {
  from = aws_organizations_policy.scp_account_protection[0]
  to   = aws_organizations_policy.scp_account_protection
}

moved {
  from = aws_organizations_policy_attachment.scp_account_protection[0]
  to   = aws_organizations_policy_attachment.scp_account_protection
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

data "aws_iam_policy_document" "resource_perimeter" {
  statement {
    sid    = "DenyAccessOutsideOrganization"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

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
