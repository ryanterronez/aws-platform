locals {
  areopagus_workload_account_id = one([
    for account in data.aws_organizations_organization.current.non_master_accounts : account.id
    if account.name == var.areopagus_workload_account_name && account.state == "ACTIVE"
  ])

  application_iam_path = "/areopagus/application/"
  guardrail_iam_path   = "/areopagus/guardrails/"

  application_role_arn = "arn:${data.aws_partition.current.partition}:iam::${local.areopagus_workload_account_id}:role${local.application_iam_path}*"
}
