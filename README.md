# AWS Platform

This repository has two independent Terraform stacks in `us-east-2`.

- **Root (`./`) — platform bootstrap.** Creates and hardens the
  `areopagus-terraform-state` S3 backend; GitHub Actions OIDC provider and
  roles; and the `terraform-state-access` role. Bootstrap state is stored at
  `aws-platform/terraform.tfstate`. Pull requests assume the read-only
  `terraform-plan` role and cannot apply bootstrap changes.
- **`organization-governance/` — organization governance.** Must run with an
  AWS Organizations management-account administrator. It creates the
  `Workloads` OU and the Areopagus workload account, then attaches
  the baseline service-allowlist, account-departure, and IAM identity guardrail
  SCPs, plus EC2 and S3 declarative policies. Its state is intentionally
  inaccessible to normal platform CI.

The Organization stack enforces management-account execution. Accounts, OUs,
and Organization policies are protected from destruction.

Apply changes to the platform root using the same administrator session:

For the governance stack, set `workload_account_email` in local
`terraform.tfvars` (never commit it), then configure its backend from
the local ignored `organization-governance/backend.hcl`. Enable the SCP, EC2
declarative, and S3 policy types before its first apply. Set
`existing_account_departure_protection_policy_id` only when equivalent
departure protection is already effective.

```cmd
set AWS_PROFILE=admin
terraform -chdir=organization-governance init -reconfigure -backend-config=backend.hcl
terraform -chdir=organization-governance plan
terraform -chdir=organization-governance apply
```

Normal platform CI cannot access governance state.

aws sso login --profile admin

set AWS_PROFILE=admin
