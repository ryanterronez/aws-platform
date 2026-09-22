# Repository Instructions

## Purpose

`aws-platform` owns the minimal AWS account, organization, identity, governance, and genuinely shared platform infrastructure needed to securely support workloads.

It is not an application repository.

Optimize for:
- simplicity
- security
- low cost
- clear ownership
- understandability
- easy local administration
- minimal infrastructure

Do not solve problems we do not currently have.

## Repository scope

This repository may own:
- AWS Organizations structure
- workload accounts and organizational units
- SCPs, RCPs, and account-level security guardrails
- AWS IAM Identity Center / bootstrap access
- genuinely shared Terraform state infrastructure
- genuinely shared CI authentication infrastructure

Application-specific infrastructure belongs in the application repository.

If a resource exists only because Areopagus or another application exists, presume that it belongs with that application unless there is a concrete platform-level reason otherwise.

Do not create application deployment foundations, application IAM roles, policies, state roles, workflows, or other machinery here merely because they may be useful later.

## Architecture

Keep the platform as small as possible.

Before introducing a new AWS service, Terraform root/state boundary, significant IAM design, networking layer, deployment mechanism, or other substantial platform component, stop and propose the design first.

Explain:
1. the current requirement,
2. why existing infrastructure is insufficient,
3. exactly what AWS resources would be created,
4. IAM and security implications,
5. recurring cost or operational burden,
6. why the capability belongs in `aws-platform`.

Do not implement the architectural change until Ryan approves it.

If implementation starts growing materially beyond the approved requirement, stop and ask again.

Do not create speculative infrastructure, future scaffolding, or abstractions for anticipated requirements.

## Local execution

Use Windows Command Prompt (`cmd`) syntax for local commands.

Never perform Git operations.

Never run Terraform, AWS CLI, shell, or other infrastructure-changing commands on Ryan's behalf.

When commands are needed, provide the exact commands for Ryan to copy and run manually.

Ryan performs Git and infrastructure operations himself.

## Local-first developer experience

When the same operation can run locally or in CI/CD, optimize the local path for simplicity.

Routine local Terraform administration should use the shortest reasonable commands, such as:

`terraform init`

`terraform plan`

`terraform apply`

Do not require Ryan to routinely provide:
- backend configuration files
- role ARNs
- repeated `-var` arguments
- CI-specific variable files
- CI-specific environment variables
- other pipeline-oriented configuration

Prefer safe checked-in defaults for normal local administration.

If CI/CD requires additional backend configuration, role assumption, variables, credentials setup, or other automation complexity, put that complexity in the workflow rather than shifting it onto the local workflow.

A one-time bootstrap requirement may be more explicit when unavoidable, but routine administration after bootstrap should remain simple.

Do not make the local workflow more complicated solely to make CI/CD easier to configure.

## Security

Security must remain strong while infrastructure stays simple.

Prefer:
- AWS IAM Identity Center / SSO for human access
- short-lived credentials
- GitHub OIDC only when GitHub genuinely needs AWS access
- least-privilege workload permissions
- strong organization-level guardrails

Do not create IAM users or long-lived AWS access keys.

Do not use `AdministratorAccess` or `PowerUserAccess` for normal CI or workload deployment roles.

Do not weaken an SCP, RCP, permissions boundary, organization policy, or other security control merely to make an application deployment easier. Reconsider the application design first.

Organization and account governance may use strong deletion protection when accidental removal would be dangerous.

Do not automatically apply the same deletion resistance to ordinary replaceable infrastructure.

## Simplicity

Prefer the smallest secure design that satisfies the current requirement.

Do not add:
- speculative infrastructure
- future scaffolding
- unnecessary Terraform roots or states
- unnecessary modules
- custom networking without a current requirement
- unnecessary IAM roles or policy layers
- deployment automation that is not currently needed
- observability or monitoring stacks without a current requirement
- queues, caches, orchestration, or other platform services for hypothetical use

Use AWS defaults when they safely satisfy the requirement.

Do not preserve complexity merely because it already exists.

When cleaning up obsolete architecture, prefer removing it rather than building another layer around it.

## Terraform

Keep Terraform boring.

Prefer:
- few Terraform roots
- few state boundaries
- direct resources
- few variables
- few outputs
- minimal abstraction
- narrow IAM policies

Create a separate Terraform root or state only when there is a real privilege, ownership, account, or lifecycle boundary.

Do not create modules merely for organization or anticipated reuse.

Do not require local users to supply configuration that can safely be encoded as repository defaults.

Pipeline-specific Terraform configuration should remain in CI/CD rather than complicating local administration.

Use the repository's existing Terraform/provider constraints unless a task explicitly includes upgrading them.

Use repository-installed Terraform skills when relevant.

## Naming and consistency

Names must accurately describe the resource, role, variable, local, output, policy, or behavior they represent.

Use consistent terminology for the same concept throughout Terraform, workflows, IAM, outputs, and documentation.

Do not leave historical names that describe an architecture or responsibility that no longer exists.

For example, a variable representing a Terraform plan role should not be named as though it represents a deployment role.

Prefer changing code identifiers to accurately describe existing AWS resources.

Do not rename or replace deployed AWS resources solely for cosmetic consistency unless Ryan explicitly approves the migration or replacement.

Do not change Terraform resource addresses casually. If a naming cleanup would affect Terraform state or cause resource replacement, stop and explain it first.

Prefer clear, boring names over clever abstractions.

## CI/CD

CI should primarily validate infrastructure changes.

Do not introduce automatic Terraform apply workflows unless Ryan explicitly approves that deployment model.

Do not expand GitHub Actions permissions, OIDC trust relationships, or AWS permissions without explaining why they are required.

Keep workflows minimal and scoped to their actual responsibility.

CI/CD may use more explicit configuration than local administration when automation requires it.

Do not simplify CI/CD by making local commands more complicated.

## Change discipline

Before modifying infrastructure:
1. inspect the relevant existing code,
2. understand what currently owns the resource,
3. identify what would be created, changed, or destroyed,
4. identify whether the change affects Terraform state,
5. prefer subtraction over adding another layer to an existing design.

Implement only the requested slice.

Do not scaffold future work.

Do not add adjacent infrastructure simply because it may eventually be useful.

When cleaning up obsolete architecture, remove associated IAM, workflows, documentation, variables, outputs, and bootstrap machinery when they no longer serve a purpose.

If something looks obsolete but its dependency or security purpose is unclear, report it instead of removing it.

## Governance safety

Treat organization-level resources differently from ordinary application infrastructure.

Do not casually remove or weaken:
- AWS Organizations accounts or OUs
- SCPs or RCPs
- account-protection controls
- identity guardrails
- public-access guardrails
- Terraform state protections
- other organization-wide security controls

Cleanup of those controls requires explicit review of their purpose and consequences.

Simplifying the repository must not mean silently weakening the security boundary.

## Documentation

Keep `README.md` accurate to the architecture that actually exists.

Remove obsolete instructions when infrastructure is removed or redesigned.

Do not document planned or hypothetical architecture as though it already exists.

Documentation should favor the normal local administrative workflow over CI implementation details.

## Completion

For meaningful infrastructure changes, report:
1. what changed,
2. files added, removed, or modified,
3. AWS resources added or removed,
4. IAM permissions or trust relationships changed,
5. Terraform state implications,
6. recurring cost impact,
7. commands Ryan needs to run manually,
8. the approximate expected Terraform plan,
9. anything uncertain that needs review.

## Guiding principle

This repository should remain small enough that one engineer can understand why every AWS resource, IAM permission, Terraform state, and workflow exists.

When in doubt, choose less infrastructure and the simpler local workflow.