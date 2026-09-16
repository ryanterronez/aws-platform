variable "aws_region" {
  description = "AWS region in which to manage resources."
  type        = string
  default     = "us-east-1"
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

variable "tags" {
  description = "Tags applied to supported AWS resources."
  type        = map(string)
  default     = {}
}
