locals {
  areopagus_workload_account_id = one([
    for account in data.aws_organizations_organization.current.non_master_accounts : account.id
    if account.name == var.areopagus_workload_account_name && account.state == "ACTIVE"
  ])

  application_iam_path = "/areopagus/application/"
  guardrail_iam_path   = "/areopagus/guardrails/"

  application_bucket_arn      = "arn:${data.aws_partition.current.partition}:s3:::areopagus-*"
  application_dynamodb_arn    = "arn:${data.aws_partition.current.partition}:dynamodb:${var.aws_region}:${local.areopagus_workload_account_id}:table/areopagus-*"
  application_lambda_arn      = "arn:${data.aws_partition.current.partition}:lambda:${var.aws_region}:${local.areopagus_workload_account_id}:function:areopagus-*"
  application_log_group_arn   = "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${local.areopagus_workload_account_id}:log-group:/aws/lambda/areopagus-*"
  application_object_arn      = "${local.application_bucket_arn}/*"
  application_role_arn        = "arn:${data.aws_partition.current.partition}:iam::${local.areopagus_workload_account_id}:role${local.application_iam_path}*"
  application_secret_arn      = "arn:${data.aws_partition.current.partition}:secretsmanager:${var.aws_region}:${local.areopagus_workload_account_id}:secret:areopagus/*"
  terraform_state_bucket_arn  = "arn:${data.aws_partition.current.partition}:s3:::${var.terraform_state_bucket_name}"
  terraform_state_lock_arn    = "${local.terraform_state_bucket_arn}/${var.areopagus_terraform_state_key}.tflock"
  terraform_state_object_arn  = "${local.terraform_state_bucket_arn}/${var.areopagus_terraform_state_key}"
}
