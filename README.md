# AWS Platform

This repository owns minimal shared AWS organization, governance, Terraform-state, and CI bootstrap infrastructure. It does not own Areopagus application resources.

## Stacks

- **Root (`./`)** creates and hardens the shared `areopagus-terraform-state` bucket and platform CI/state access. Bootstrap state uses `aws-platform/terraform.tfstate`.
- **`organization-governance/`** creates the `Workloads` OU and the Areopagus workload account and applies organization guardrails. Its state is intentionally unavailable to normal platform CI.
- **`areopagus-workload-foundation/`** is an administrator-only bootstrap stack for the Areopagus workload account.

## Areopagus workload foundation

The foundation discovers the one active Organization account named `Areopagus`, assumes only its Organization-created `OrganizationAccountAccessRole`, and creates no application resources.

It creates one GitHub Actions OIDC provider and two workload-account roles:

- `areopagus-github-actions-deployment` trusts only the approved immutable Areopagus `main`-branch OIDC subject. It can manage only the approved Areopagus application boundary: S3, Transcribe, DynamoDB, Lambda, API Gateway, CloudWatch Logs, Secrets Manager, and bounded application IAM.
- `areopagus-github-actions-plan` trusts only the approved immutable same-repository pull-request OIDC subject. It has read-only discovery access within the same service boundary.

GitHub Actions never trusts or assumes `OrganizationAccountAccessRole`. Pull requests never receive deployment permissions.

Application IAM roles must be below `/areopagus/application/` and use the `AreopagusApplicationPermissionsBoundary` output. Deployment credentials can create and manage only roles below that path, must require the boundary at creation, and can pass only those roles. They cannot alter the boundary.

Application resources use the `areopagus-*` boundary and application secrets use `areopagus/*`. Where an AWS API supports resource ARNs or resource-account conditions, the policies scope permissions accordingly. APIs that only support `Resource = "*"` are limited to the approved service and explicit action set.

## Areopagus Terraform state

Areopagus uses exactly one Terraform state object:

```text
areopagus/terraform.tfstate
```

Its lock object is:

```text
areopagus/terraform.tfstate.tflock
```

The shared platform state-bucket policy directly authorizes the two exact GitHub workload roles; Terraform does not assume a separate platform state role.

- The deployment role can list the exact key, get and put the state object, and get/put/delete its lock object.
- The plan role can list the exact key, get the state object, and get/put/delete its lock object.
- No Areopagus role can delete the state object or access another Terraform state object in the bucket.

The state bucket retains shared versioning, SSE-S3 encryption, public-access blocking, bucket-owner-enforced ownership, and an explicit deny for insecure transport.

The Areopagus repository configures the S3 backend with the bucket, region, and exact key outputs. It does **not** configure a backend `assume_role`. Its GitHub workflows require `id-token: write` and `contents: read`; the main deployment workflow assumes the deployment role and the pull-request workflow assumes the plan role. Do not use `-lock=false`.

The workload-foundation stack has an empty S3 backend declaration. Use its ignored local `backend.hcl` with the existing platform `terraform-state-access` role for administrator bootstrap state; this role is unrelated to Areopagus application state access.

## Local administration

Ryan uses existing IAM Identity Center administrator credentials directly for local Terraform, S3 uploads, Transcribe operations, and other manual Areopagus administration. This foundation creates no additional human-access role or local state-access mechanism.
