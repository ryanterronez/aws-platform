variable "aws_region" {
  description = "AWS region in which to manage resources."
  type        = string
  default     = "us-east-2"
}

variable "areopagus_deployment_role_name" {
  description = "Name of the workload-account role that Areopagus GitHub Actions assumes through OIDC."
  type        = string
  default     = "areopagus-github-actions-deployment"
}

variable "areopagus_github_oidc_subject" {
  description = "Exact immutable GitHub OIDC subject trusted to deploy Areopagus from its main branch."
  type        = string
  default     = "repo:ryanterronez@48932656/areopagus@1373118440:ref:refs/heads/main"
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

variable "areopagus_workload_account_id" {
  description = "AWS account ID of the Organization-created Areopagus workload account."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.areopagus_workload_account_id))
    error_message = "areopagus_workload_account_id must be a 12-digit AWS account ID."
  }
}

variable "areopagus_workload_bootstrap_role_name" {
  description = "Name of the tightly scoped bootstrap role created by AWS Organizations in the Areopagus workload account."
  type        = string
  default     = "OrganizationAccountAccessRole"
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
