variable "areopagus_deployment_role_name" {
  description = "Name of the workload-account IAM role assumed by Areopagus GitHub Actions."
  type        = string
  default     = "areopagus-github-actions-deployment"
}

variable "areopagus_github_oidc_plan_subject" {
  description = "Exact immutable GitHub OIDC subject trusted to plan Areopagus Terraform from same-repository pull requests."
  type        = string
  default     = "repo:ryanterronez@48932656/areopagus@1373118440:pull_request"
}

variable "areopagus_github_oidc_subject" {
  description = "Exact immutable GitHub OIDC subject trusted to deploy Areopagus from its main branch."
  type        = string
  default     = "repo:ryanterronez@48932656/areopagus@1373118440:ref:refs/heads/main"
}

variable "areopagus_terraform_state_role_name" {
  description = "Name of the platform-account role that grants access only to Areopagus Terraform state."
  type        = string
  default     = "areopagus-terraform-state-access"
}

variable "areopagus_plan_role_name" {
  description = "Name of the workload-account IAM role assumed by Areopagus pull requests."
  type        = string
  default     = "areopagus-github-actions-plan"
}

variable "areopagus_terraform_plan_state_role_name" {
  description = "Name of the platform-account role that grants Areopagus pull requests read-only Terraform state access."
  type        = string
  default     = "areopagus-terraform-plan-state-access"
}

variable "areopagus_workload_account_name" {
  description = "Unique active AWS Organizations account name for the Areopagus workload."
  type        = string
  default     = "Areopagus"
}

variable "areopagus_workload_bootstrap_role_name" {
  description = "Organization-created administrator bootstrap role name in the Areopagus workload account."
  type        = string
  default     = "OrganizationAccountAccessRole"
}

variable "aws_region" {
  description = "AWS Region in which to manage resources."
  type        = string
  default     = "us-east-2"
}

variable "tags" {
  description = "Tags applied to supported AWS resources."
  type        = map(string)
  default     = {}
}
