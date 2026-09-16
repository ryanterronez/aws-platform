output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions to assume through OIDC."
  value       = aws_iam_role.github_actions.arn
}
