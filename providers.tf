provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "areopagus"
  region = var.aws_region

  assume_role {
    role_arn = "arn:${data.aws_partition.current.partition}:iam::${local.areopagus_workload_account_id}:role/OrganizationAccountAccessRole"
  }

  default_tags {
    tags = var.tags
  }
}

provider "github" {
  owner = "ryanterronez"
}
