output "areopagus_deployment_role_arn" {
  description = "Workload-account IAM role ARN for Areopagus GitHub Actions to assume through OIDC."
  value       = local.areopagus_deployment_role_arn
}

output "areopagus_terraform_state_bucket_name" {
  description = "S3 bucket that stores Areopagus Terraform state."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "areopagus_terraform_state_key_prefix" {
  description = "S3 key prefix reserved for Areopagus Terraform state and lockfiles."
  value       = var.areopagus_terraform_state_key_prefix
}

output "areopagus_terraform_state_region" {
  description = "AWS Region containing the Areopagus Terraform state bucket."
  value       = var.aws_region
}

output "areopagus_terraform_state_role_arn" {
  description = "Platform-account IAM role ARN that grants access only to Areopagus Terraform state."
  value       = aws_iam_role.areopagus_terraform_state.arn
}

output "areopagus_terraform_plan_role_arn" {
  description = "Workload-account IAM role ARN for Areopagus pull requests to assume through GitHub OIDC."
  value       = local.areopagus_plan_role_arn
}

output "areopagus_terraform_plan_state_role_arn" {
  description = "Platform-account IAM role ARN that provides Areopagus pull requests read-only Terraform state access."
  value       = aws_iam_role.areopagus_terraform_plan_state.arn
}
