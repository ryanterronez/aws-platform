# AWS Platform

This repository owns minimal shared AWS organization, governance, Terraform-state, and CI bootstrap infrastructure. It does not own application resources.

## Stacks

- **Root (`./`)** creates and hardens the shared `areopagus-terraform-state` bucket and platform CI/state access. Its state uses `aws-platform/terraform.tfstate`.
- **`organization-governance/`** creates the `Workloads` OU and the Areopagus workload account and applies organization guardrails. Its state is intentionally unavailable to normal platform CI.

## Local administration

Ryan uses existing IAM Identity Center administrator credentials directly for local Terraform administration. The root state backend uses the `terraform-state-access` role.
