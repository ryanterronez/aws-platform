data "aws_organizations_organization" "current" {}

data "aws_partition" "current" {}

terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
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
