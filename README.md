# Infrastructure Platform

Terraform infrastructure for any application on Google Cloud Platform.

## Prerequisites

- Google Cloud CLI (`gcloud`) installed and authenticated
- Terraform installed
- GCP projects created for each environment and enable billing
  Ex:
  - **Dev**: `test-app-dev`
  - **Production**: `test-app-prod`
- Update the `terraform.tfcars`file

## Quick Start

### 1. Setup Service Account for Terraform and enable Apis

- `./scripts/setup-service-account.sh --project-id vunapay-project-dev-1`
- `./scripts/setup-required-apis.sh --project-id vunapay-project-dev-1`

### 2. Apply Terraform

- `cd envs/dev && terraform plan && terraform apply`
- `cd envs/prod && terraform plan && terraform apply`

### 3. Setup the Environmental and Secret variables in Github

After the terraform apply finished, update secret & environment variables in the github repositories

1. Create a key for `github-actions-sa` in GCP and crate or update the content into the `GCP_SA_KEY`in the github repo
2. Repeat the same things for the `GCP_PROJECT_ID` and `GCP_REGION` Environment variables in the repo

### 4. Setup the Kubernetes Cluster

1. Load the cluster crendentials `./scripts/utils/update-kubectl-credentials.sh`
2. Set up the k8s cluser via `cd vunapay-k8s-deployments && ./scripts/setup.sh`

### 5. Update the static files

Update the image.repository and other gcp variables accordingly in the `vunapay-k8s-deployments/values/dev/main-application-service.yaml`

### Manual Control

```bash
# Save costs (scale to 0 nodes)
./scripts/utils/scale-down.sh -p test-app-dev

# Resume work (scale to 1 node)
./scripts/utils/scale-up.sh -p test-app-dev
```

Check cluster status `kubectl get nodes`

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
  - `roles/servicenetworking.networksAdmin` Service Networking Admin
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

### Destroy the project setup

`   export GOOGLE_APPLICATION_CREDENTIALS="../../terraform-key-${PROJECT_ID}.json"
   terraform destroy`
