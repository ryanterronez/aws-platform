# AWS Platform

The existing platform root manages the Terraform backend and GitHub OIDC roles.
Its PR workflow is unchanged.

The management account is for organization governance and account creation.
The Areopagus member account is for the future application.

`organization-governance/` reads the existing Organization and manages the Workloads
OU, Areopagus account, two SCPs, and S3/EC2 declarative policies attached to Workloads.
Apply it separately using your management-account Identity Center administrator
session and its own state key in the existing bucket.

Set `workload_account_email` in local `terraform.tfvars`; configure the backend from
`backend.hcl.example`. Enable SCP, EC2 declarative, and S3 policy types first.
Set `existing_account_departure_protection_policy_id` only if equivalent protection
is already effective. Accounts, OUs, and policies are protected from destruction.

```cmd
set AWS_PROFILE=admin
terraform -chdir=organization-governance init -reconfigure -backend-config=backend.hcl
terraform -chdir=organization-governance plan
terraform -chdir=organization-governance apply
```

Normal platform CI cannot access governance state.

aws sso login --profile admin

set AWS_PROFILE=admin
