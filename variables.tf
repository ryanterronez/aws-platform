variable "aws_region" {
  description = "AWS region in which to manage resources."
  type        = string
  default     = "us-east-2"
}

variable "github_organization" {
  description = "GitHub organization or user that owns the allowed repository."
  type        = string
  default     = "ryanterronez"
}

variable "github_actions_role_name" {
  description = "Name of the IAM role assumed by GitHub Actions."
  type        = string
  default     = "github-actions-oidc"
}

variable "terraform_state_bucket_name" {
  description = "Globally unique name of the S3 bucket that stores Terraform state."
  type        = string
}

variable "terraform_state_key_prefix" {
  description = "S3 key prefix to which the state-access role is restricted."
  type        = string
  default     = "aws-platform"
}

variable "terraform_state_role_name" {
  description = "Name of the IAM role that can read and write Terraform state."
  type        = string
  default     = "terraform-state-access"
}

variable "tags" {
  description = "Tags applied to supported AWS resources."
  type        = map(string)
  default     = {}
}
