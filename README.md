# Infrastructure Platform

Terraform infrastructure for any application on Google Cloud Platform.

## Prerequisites

- Google Cloud CLI (`gcloud`) installed and authenticated
- Terraform installed
- GCP projects created for each environment and enable billing
  Ex:
  - **Dev**: `test-app-dev`
  - **Staging**: `test-app-dev`
  - **Production**: `test-app-dev`
- Update the `provider.tf` files with the created projectIds

## Quick Start

### 1. Setup Environment

```bash
# Setup dev environment
./scripts/setup.sh --project-id test-app-dev --environment dev

# Setup staging environment
./scripts/setup.sh --project-id test-app-stage --environment stage

# Setup production environment
./scripts/setup.sh --project-id test-app-prod --environment prod
```

### 2. Deploy & Destroy Infrastructure

```bash
# Deploy to dev
./scripts/run-terraform.sh --environment dev --command plan
./scripts/run-terraform.sh --environment dev --command apply
```

Or to destroy `./scripts/run-terraform.sh --environment dev --command destroy`

### 3. Access Cluster

This command add the cluster config to`.kube/config` file
`./scripts/utils/update-kubectl-credentials.sh`
Check cluster status `kubectl get nodes`

## Cost Optimization

### Manual Control

```bash
# Save costs (scale to 0 nodes)
./scripts/utils/scale-down.sh -p test-app-dev

# Resume work (scale to 1 node)
./scripts/utils/scale-up.sh -p test-app-dev
```

Check cluster status `kubectl get nodes`

### Automated Scheduling

TODO

## Security

- Service account key: `terraform-key.json` (excluded from git)
- Shared across all environments
- Minimal required permissions

## Requirements

We need the following service accounts to provision the GCP Services in order to use terraform to setup the cluster and manage the deployments via github acitons

### 1. GitHub Actions Service Account

- **Example name:** `github-actions@ya-test-project-1-dev.iam.gserviceaccount.com`
- **Purpose:** Used by GitHub Actions workflows to deploy to GKE and push Docker images to Artifact Registry.
- **Required Roles:**
  - `roles/artifactregistry.writer` Artifact Registry Writer`(push images)
  - Artifact Registry Administrator & REader as well
  - `roles/container.developer` Kubernetes Engine Developer (deploy to GKE)
  - `roles/storage.admin` Storage Admin (if using GCS for state or artifacts)

### 2. Terraform Service Account

- **Example name:** `terraform-sa@ya-test-project-1-dev.iam.gserviceaccount.com`
- **Purpose:** Used by Terraform to provision and manage all required cloud services.
- **Required Roles:**
  - `roles/cloudsql.admin`
  - `roles/compute.admin`
  - `roles/container.admin`
  - `roles/iam.serviceAccountUser`
  - `roles/servicenetworking.networksAdmin`
  - `roles/storage.objectAdmin`

### 3. Compute Engine Default Service Account

- **Example principal:** `502258144698-compute@developer.gserviceaccount.com`
- **Purpose:** Used by GCP for default compute operations (VMs, etc).
- **Roles:**
  - `roles/editor` (default, but consider restricting for security)

## Useful Terraform commands

- Destroy only a module `terraform destroy -target=module.gke`
- Apply only a module `terraform apply -target=module.gke`
- Check the tracked resources `terraform state list`
