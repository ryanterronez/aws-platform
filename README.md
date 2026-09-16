# AWS Platform

Terraform foundation for AWS resources managed through GitHub Actions using
OpenID Connect (OIDC). No long-lived AWS access keys are required in GitHub.

## Prerequisites

- Terraform 1.6 or later
- An AWS account and permissions to create IAM OIDC providers and roles
- A GitHub repository

## Configure

Provide the GitHub organization or user that owns the `aws-platform`
repository. The OIDC role can be assumed only from its `main` branch:

```hcl
github_organization = "your-github-organization"
terraform_state_bucket_name = "areopagus-terraform-state"
```

Save those values in a local `terraform.tfvars` file (ignored by Git) or pass
them with `-var`.

```sh
terraform init
terraform plan
terraform apply
```

After apply, configure GitHub Actions to request `id-token: write` and assume
the `github_actions_role_arn` output.
