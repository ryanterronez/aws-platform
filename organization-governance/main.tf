provider "aws" {
  region = "us-east-2"
}

data "aws_organizations_organization" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = data.aws_organizations_organization.current.roots[0].id

  lifecycle {
    prevent_destroy = true

    precondition {
      condition     = data.aws_caller_identity.current.account_id == data.aws_organizations_organization.current.master_account_id
      error_message = "Organization governance must execute in the existing Organization's management account."
    }
  }
}

resource "aws_organizations_account" "areopagus" {
  name              = var.workload_account_name
  email             = var.workload_account_email
  parent_id         = aws_organizations_organizational_unit.workloads.id
  role_name         = "OrganizationAccountAccessRole"
  close_on_deletion = false

  lifecycle {
    prevent_destroy = true
  }
}
