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
  SCPs; a resource-perimeter RCP; and EC2 and S3 declarative policies. Its
  state is intentionally inaccessible to normal platform CI.

The Organization stack enforces management-account execution. Accounts, OUs,
and Organization policies are protected from destruction.

Apply changes to the platform root using the same administrator session:

For the governance stack, set `workload_account_email` in local
`terraform.tfvars` (never commit it), then configure its backend from
the local ignored `organization-governance/backend.hcl`. Enable the SCP, EC2
declarative, S3, and RCP policy types before its first apply. Set
`existing_account_departure_protection_policy_id` only when equivalent
departure protection is already effective.

```cmd
set AWS_PROFILE=admin
terraform -chdir=organization-governance init -reconfigure -backend-config=backend.hcl
terraform -chdir=organization-governance plan
terraform -chdir=organization-governance apply
```

Normal platform CI cannot access governance state.

## Areopagus workload deployment foundation

The root stack also creates the minimum cross-account foundation for the
separate `ryanterronez/areopagus` application repository. It discovers the
active Organization account named `Areopagus` automatically; no local Terraform
input or GitHub repository variable is required. The lookup fails safely if no
active account, or more than one active account, has that name. Change
`areopagus_workload_account_name` only if the governance stack's workload
account name is intentionally changed as well.

During bootstrap, the platform administrator assumes the Organization-created
`OrganizationAccountAccessRole` in that workload account to create its GitHub
OIDC provider and `areopagus-github-actions-deployment` role. This temporary
bootstrap path is usable only by the platform administrator; GitHub Actions
does not trust or assume `OrganizationAccountAccessRole`.

The deployment role trusts exactly this customized immutable GitHub subject and
the `sts.amazonaws.com` audience:

```text
repo:ryanterronez@48932656/areopagus@1373118440:ref:refs/heads/main
```

It trusts no pull requests, tags, other branches, forks, wildcard repositories,
or mutable repository-name-only subjects. Do not configure a GitHub Environment
for this workflow unless its environment-form OIDC subject is also explicitly
trusted; the role currently accepts only the branch subject above. Consequently,
only workflow runs for changes merged to `main` are eligible to deploy.

Terraform state for the application uses the `areopagus/*` key convention in
`areopagus-terraform-state` (for example, `areopagus/terraform.tfstate` and its
S3 lockfile). The deployment role can only assume the separate
`areopagus-terraform-state-access` role; that role can list and read/write only
the `areopagus/*` prefix. It has no access to `aws-platform/*`, including the
governance prefix. Bucket encryption, versioning, public-access blocking,
lockfile permissions, and the deny-insecure-transport policy remain shared
controls managed by this stack.

The deployment role intentionally starts without AWS application-resource
permissions. When the Areopagus Terraform configuration is introduced, extend
its inline policy with only the actions and resource ARNs required by those
declared resources. Do not attach administrative access.

The future Areopagus workflow must still configure:

- `permissions: id-token: write` and `contents: read`;
- `aws-actions/configure-aws-credentials` with the
  `areopagus_deployment_role_arn` output and `us-east-2`;
- the S3 backend bucket/key/region from the Areopagus state outputs, with its
  backend `assume_role` set to `areopagus_terraform_state_role_arn`; and
- a trigger that runs the deployment job only after a merge to `main` (for
  example, a `push` workflow restricted to `main`).

No changes to the Areopagus repository are made by this stack.

aws sso login --profile admin

set AWS_PROFILE=admin
