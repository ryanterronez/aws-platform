terraform {
  backend "s3" {
    bucket       = "areopagus-terraform-state"
    key          = "aws-platform/terraform.tfstate"
    region       = "us-east-2"
    use_lockfile = true

    assume_role = {
      role_arn = "arn:aws:iam::503353372972:role/terraform-state-access"
    }
  }
}