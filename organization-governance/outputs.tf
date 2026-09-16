output "organization_id" {
  value = data.aws_organizations_organization.current.id
}

output "workloads_ou_id" {
  value = aws_organizations_organizational_unit.workloads.id
}

output "workload_account_id" {
  value = aws_organizations_account.areopagus.id
}