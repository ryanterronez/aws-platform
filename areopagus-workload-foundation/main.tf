data "aws_organizations_organization" "current" {}

data "aws_partition" "current" {}

locals {
  areopagus_workload_account_id = one([
    for account in data.aws_organizations_organization.current.non_master_accounts : account.id
    if account.name == "Areopagus" && account.state == "ACTIVE"
  ])
}

terraform {
  backend "s3" {}
}

provider "aws" {
  region = "us-east-2"
}

provider "aws" {
  alias  = "areopagus_workload"
  region = "us-east-2"

  assume_role {
    role_arn = "arn:${data.aws_partition.current.partition}:iam::${local.areopagus_workload_account_id}:role/OrganizationAccountAccessRole"
  }
}
