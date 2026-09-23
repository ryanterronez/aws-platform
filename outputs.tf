output "areopagus_github_actions_role_arn" {
  description = "ARN of the GitHub Actions role for Areopagus Terraform workflows."
  value       = aws_iam_role.areopagus_github_actions.arn
}
