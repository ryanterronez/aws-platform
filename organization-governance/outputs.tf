output "organization_id" {
  description = "ID of the AWS Organization managed by this stack."
  value = data.aws_organizations_organization.current.id
}

output "workloads_ou_id" {
  description = "ID of the Workloads organizational unit."
  value = aws_organizations_organizational_unit.workloads.id
}

output "workload_account_id" {
  description = "ID of the Areopagus workload account."
  value = aws_organizations_account.areopagus.id
}
