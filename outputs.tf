output "areopagus_deployment_role_arn" {
  description = "Workload-account IAM role ARN for Areopagus GitHub Actions to assume through OIDC."
  value       = local.areopagus_deployment_role_arn
}

output "areopagus_terraform_plan_role_arn" {
  description = "Workload-account IAM role ARN for Areopagus pull requests to assume through OIDC."
  value       = local.areopagus_plan_role_arn
}

output "areopagus_terraform_state_bucket_name" {
  description = "S3 bucket that stores Areopagus Terraform state."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "areopagus_terraform_state_key" {
  description = "Exact S3 key reserved for the single Areopagus Terraform state file."
  value       = var.areopagus_terraform_state_key
}

output "areopagus_terraform_state_region" {
  description = "AWS Region containing the Areopagus Terraform state bucket."
  value       = var.aws_region
}
