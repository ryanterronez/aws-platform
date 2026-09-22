data "aws_organizations_organization" "current" {}

locals {
  areopagus_workload_account_id = one([
    for account in data.aws_organizations_organization.current.non_master_accounts : account.id
    if account.name == var.areopagus_workload_account_name && account.state == "ACTIVE"
  ])

  areopagus_deployment_role_arn = "arn:${data.aws_partition.current.partition}:iam::${local.areopagus_workload_account_id}:role/areopagus-github-actions-deployment"
  areopagus_plan_role_arn       = "arn:${data.aws_partition.current.partition}:iam::${local.areopagus_workload_account_id}:role/${var.areopagus_plan_role_name}"
}
