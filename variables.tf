variable "aws_region" {
  description = "AWS region in which to manage resources."
  type        = string
  default     = "us-east-2"
}

variable "areopagus_plan_role_name" {
  description = "Name of the workload-account role that GitHub Actions pull requests use for Terraform planning."
  type        = string
  default     = "areopagus-github-actions-plan"
}

variable "areopagus_terraform_state_key_prefix" {
  description = "S3 key prefix to which the Areopagus state-access role is restricted."
  type        = string
  default     = "areopagus"
}

variable "areopagus_terraform_state_role_name" {
  description = "Name of the platform-account role that can read and write Areopagus Terraform state."
  type        = string
  default     = "areopagus-terraform-state-access"
}

variable "areopagus_terraform_plan_state_role_name" {
  description = "Name of the platform-account role that grants read-only Areopagus Terraform state access to pull requests."
  type        = string
  default     = "areopagus-terraform-plan-state-access"
}

variable "areopagus_workload_account_name" {
  description = "Unique active AWS Organizations account name for the Areopagus workload."
  type        = string
  default     = "Areopagus"
}

variable "github_oidc_subject_repository" {
  description = "Repository prefix in the customized GitHub OIDC subject, including immutable owner and repository IDs."
  type        = string
  default     = "repo:ryanterronez@48932656/aws-platform@1373146850"

  validation {
    condition     = startswith(var.github_oidc_subject_repository, "repo:")
    error_message = "github_oidc_subject_repository must start with repo:."
  }
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
