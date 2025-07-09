# IAM Service Account Module

This module creates a Google Cloud service account, assigns IAM roles, and (optionally) creates a key for use in automation, CI/CD, or Terraform workflows.

## Usage

```hcl
module "github_actions_sa" {
  source      = "../../modules/iam"
  account_id  = "github-actions-sa"
  display_name = "GitHub Actions Service Account"
  project_id  = var.project_id
  iam_roles   = [
    "roles/artifactregistry.writer",
    "roles/container.developer",
    "roles/storage.admin"
  ]
  create_key  = true # Set to true if you need a key for CI/CD
}
```

## Variables

| Name         | Type         | Description                                        | Required | Default |
| ------------ | ------------ | -------------------------------------------------- | -------- | ------- |
| account_id   | string       | The service account ID (no domain)                 | yes      |         |
| display_name | string       | The display name for the service account           | yes      |         |
| project_id   | string       | The GCP project ID                                 | yes      |         |
| iam_roles    | list(string) | List of IAM roles to assign to the service account | yes      |         |
| create_key   | bool         | Whether to create and output a service account key | no       | false   |

## Outputs

| Name        | Description                                      |
| ----------- | ------------------------------------------------ |
| email       | The email address of the created service account |
| key_private | The private key (if created, sensitive output)   |

## Example: Terraform Service Account

```hcl
module "terraform_sa" {
  source      = "../../modules/iam"
  account_id  = "terraform-sa"
  display_name = "Terraform Service Account"
  project_id  = var.project_id
  iam_roles   = [
    "roles/cloudsql.admin",
    "roles/compute.admin",
    "roles/container.admin",
    "roles/iam.serviceAccountUser",
    "roles/servicenetworking.networksAdmin",
    "roles/storage.objectAdmin"
  ]
  create_key  = true
}
```
