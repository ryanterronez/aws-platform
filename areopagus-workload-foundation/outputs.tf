output "areopagus_deployment_role_arn" {
  description = "Workload-account IAM role ARN for Areopagus GitHub Actions to assume through OIDC."
  value       = aws_iam_role.deployment.arn
}
