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
