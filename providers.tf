provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

provider "github" {
  owner = "ryanterronez"
}
