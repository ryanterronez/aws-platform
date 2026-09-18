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

The foundation is split along its privilege boundary:

- **Root (`./`)** creates `areopagus-terraform-state-access` in the platform
  account. The ordinary pull-request plan workflow runs only against this root
  stack and never assumes a workload-account administrator role.
- **`areopagus-workload-foundation/`** is an administrator-only bootstrap stack.
  It discovers the single active Organization account named `Areopagus`, assumes
  its Organization-created `OrganizationAccountAccessRole`, and creates the
  GitHub OIDC provider and deployment role. It has no GitHub Actions workflow.

The administrator-only stack must use its own local ignored backend
configuration at `areopagus-workload-foundation/backend.hcl`. Store its state
under an `aws-platform/` key using the existing `terraform-state-access` role.
Apply it first so its deployment role exists, then apply the root stack to
create the state role that trusts it. The lookup fails safely if no active
account, or more than one active account, has the name `Areopagus`. Change the
same account-name variable in both stacks only if the governance workload
account name is intentionally changed.

`OrganizationAccountAccessRole` has administrative permissions and is usable
only by the administrator bootstrap stack. GitHub Actions never trusts or
assumes it.

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

Same-repository pull requests use a separate, read-only planning path. The
administrator-only workload-foundation stack creates
`areopagus-github-actions-plan`, whose OIDC trust accepts only this immutable
GitHub pull-request subject:

```text
repo:ryanterronez@48932656/areopagus@1373118440:pull_request
```

GitHub's `pull_request` subject is issued only for pull requests originating in
the repository, not forks. The plan role has AWS managed `ReadOnlyAccess` in
the workload account and can assume only
`areopagus-terraform-plan-state-access` in the platform account. That state
role can list and read `areopagus/*` state objects, and create/remove only the
`.tflock` objects required by Terraform's state lock. It cannot modify or
delete a `.tfstate` object. It cannot access `aws-platform/*`.

The original `terraform-plan` role remains restricted to the `aws-platform`
repository; it is not trusted by, or used for, Areopagus workflows.

Terraform state for the application uses the `areopagus/*` key convention in
`areopagus-terraform-state` (for example, `areopagus/terraform.tfstate` and its
S3 lockfile). The deployment role can only assume the separate
`areopagus-terraform-state-access` role; that role can list and read/write only
the `areopagus/*` prefix. It has no access to `aws-platform/*`, including the
governance prefix. Bucket encryption, versioning, public-access blocking,
lockfile permissions, and the deny-insecure-transport policy remain shared
controls managed by this stack.

The deployment role can manage application resources permitted by the Workloads
SCP service allowlist. Its customer-managed policy intentionally excludes IAM,
Organizations, IAM Identity Center, and unrestricted STS; the SCP remains the
account-wide maximum service boundary. The role may assume only its dedicated
platform state-access role.

The deployment role can also manage application IAM roles only below
`/areopagus/application/`. Every application role must set
the `areopagus_application_permissions_boundary_arn` output as its permissions
boundary. That boundary prevents application roles from gaining IAM,
Organizations, Identity Center, or STS permissions, even if their Terraform
policy is broader. The deployment role cannot alter the guardrail policies or
remove an application role's boundary.

Application roles use inline policies only. The deployment role may pass only
roles in the application role path. Keep their trust policies limited to the
intended AWS service and use `aws:SourceAccount` and, where the service
supports it, `aws:SourceArn` to prevent confused-deputy access.

The future Areopagus workflow must still configure:

- `permissions: id-token: write` and `contents: read`;
- `aws-actions/configure-aws-credentials` with the
  `areopagus_deployment_role_arn` output and `us-east-2`;
- the S3 backend bucket/key/region from the Areopagus state outputs, with its
  backend `assume_role` set to `areopagus_terraform_state_role_arn`; and
- a trigger that runs the deployment job only after a merge to `main` (for
  example, a `push` workflow restricted to `main`).

Its pull-request plan workflow must instead use the
`areopagus_terraform_plan_role_arn` output with
`aws-actions/configure-aws-credentials`, and set its S3 backend `assume_role`
to `areopagus_terraform_plan_state_role_arn`. Do not pass
`-lock=false`: the plan-state role permits the lock object while preserving
read-only state access.

No changes to the Areopagus repository are made by this stack.

aws sso login --profile admin

set AWS_PROFILE=admin
