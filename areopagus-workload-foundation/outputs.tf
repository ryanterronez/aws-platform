output "areopagus_application_permissions_boundary_arn" {
  description = "Required permissions boundary ARN for Areopagus Terraform-managed application roles."
  value       = aws_iam_policy.application_boundary.arn
}

output "areopagus_deployment_role_arn" {
  description = "Workload-account IAM role ARN for Areopagus GitHub Actions to assume through OIDC."
  value       = aws_iam_role.deployment.arn
}

output "areopagus_local_terraform_role_arn" {
  description = "Workload-account IAM role ARN for local Terraform use by management-account administrators."
  value       = aws_iam_role.local_terraform.arn
}

output "areopagus_plan_role_arn" {
  description = "Workload-account IAM role ARN for Areopagus pull requests to assume through GitHub OIDC."
  value       = aws_iam_role.plan.arn
}
