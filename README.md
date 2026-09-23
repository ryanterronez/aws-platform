# AWS Platform

This repository owns minimal shared AWS organization, governance, Terraform-state, and CI bootstrap infrastructure. It does not own application resources.

## Stacks

- **Root (`./`)** creates and hardens the shared `areopagus-terraform-state` bucket, platform CI/state access, and the Areopagus GitHub Actions bootstrap role. Its state uses `aws-platform/terraform.tfstate`.
- **`organization-governance/`** creates the `Workloads` OU and the Areopagus workload account and applies organization guardrails. Its state is intentionally unavailable to normal platform CI.

## Local administration

Ryan uses existing IAM Identity Center administrator credentials directly for local Terraform administration. The root state backend uses the `terraform-state-access` role.

## Areopagus GitHub Actions bootstrap

The root stack discovers the active `Areopagus` AWS account through AWS Organizations and assumes its existing `OrganizationAccountAccessRole` to create the `areopagus-github-actions` role and GitHub OIDC provider in that workload account. The role trusts only the immutable GitHub OIDC subjects for `ryanterronez/areopagus` pull requests and the `main` branch.

Areopagus application IAM roles and policies created by Terraform must use the `/areopagus/` path. Application S3 buckets must begin with `areopagus-app-`; this deliberately prevents the application permission from overlapping the shared state bucket.
