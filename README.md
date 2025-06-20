# Infrastructure Platform

Terraform infrastructure for any application on Google Cloud Platform.

## Quick Start

### 1. Setup Environment

```bash
# Setup dev environment
./scripts/setup.sh --project-id my-project-dev --environment dev

# Setup staging environment
./scripts/setup.sh --project-id my-project-stage --environment stage

# Setup production environment
./scripts/setup.sh --project-id my-project-prod --environment prod
```

### 2. Deploy Infrastructure

```bash
# Deploy to dev
cd envs/dev
terraform plan
terraform apply

# Deploy to staging
cd ../stage
terraform plan
terraform apply

# Deploy to production
cd ../prod
terraform plan
terraform apply
```

## Scripts

### Setup Scripts

| Script                       | Purpose                         | Usage                                                                        |
| ---------------------------- | ------------------------------- | ---------------------------------------------------------------------------- |
| `setup.sh`                   | Complete environment setup      | `./scripts/setup.sh --project-id <id> --environment <env>`                   |
| `setup-credentials.sh`       | Set credentials for environment | `./scripts/setup-credentials.sh <env>`                                       |
| `setup-required-apis.sh`     | Enable GCP APIs                 | `./scripts/setup-required-apis.sh --project-id <id>`                         |
| `setup-service-account.sh`   | Create service account          | `./scripts/setup-service-account.sh --project-id <id>`                       |
| `setup-terraform-backend.sh` | Setup Terraform backend         | `./scripts/setup-terraform-backend.sh --project-id <id> --environment <env>` |

### Cost Management Scripts

| Script                      | Purpose                               | Usage                                            |
| --------------------------- | ------------------------------------- | ------------------------------------------------ |
| `utils/scale-down.sh`       | Scale cluster to 0 nodes (save costs) | `./scripts/utils/scale-down.sh`                  |
| `utils/scale-up.sh`         | Scale cluster to 1 node               | `./scripts/utils/scale-up.sh`                    |
| `utils/schedule-cluster.sh` | Automated scheduling                  | `./scripts/utils/schedule-cluster.sh {up\|down}` |

### Utility Scripts

| Script                                | Purpose                          | Usage                                           |
| ------------------------------------- | -------------------------------- | ----------------------------------------------- |
| `run-terraform.sh`                    | Run Terraform with proper config | `./scripts/run-terraform.sh <env> <command>`    |
| `utils/update-kubectl-credentials.sh` | Update kubectl config            | `./scripts/utils/update-kubectl-credentials.sh` |

## Environment Configuration

### Project IDs (Customize for your project)

- **Dev**: `my-project-dev`
- **Staging**: `my-project-stage`
- **Production**: `my-project-prod`

### Network CIDRs

- **Dev**: `10.0.0.0/24`
- **Staging**: `10.1.0.0/24`
- **Production**: `10.2.0.0/24`

## Cost Optimization

### Manual Control

```bash
# Save costs (scale to 0 nodes)
./scripts/utils/scale-down.sh

# Resume work (scale to 1 node)
./scripts/utils/scale-up.sh
```

### Automated Scheduling

```bash
# Setup weekday schedule (9 AM - 6 PM)
crontab -e
# Add: 0 9 * * 1-5 ./scripts/utils/schedule-cluster.sh up
# Add: 0 18 * * 1-5 ./scripts/utils/schedule-cluster.sh down
```

**Savings**: ~$13-15/month when scaled down

## Common Commands

### Terraform Operations

```bash
# Initialize
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy infrastructure
terraform destroy
```

### Cluster Access

```bash
# Get cluster credentials
gcloud container clusters get-credentials <cluster-name> --region us-central1

# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces
```

### Troubleshooting

```bash
# Check authentication
gcloud auth list

# Verify project
gcloud config get-value project

# Check APIs enabled
gcloud services list --enabled
```

## File Structure

```
terraform-infra/
├── envs/                    # Environment configurations
│   ├── dev/
│   ├── stage/
│   └── prod/
├── modules/                 # Reusable Terraform modules
│   ├── gke/
│   ├── network/
│   └── sql/
├── scripts/                 # Automation scripts
│   ├── utils/              # Utility scripts
│   └── *.sh               # Setup scripts
└── docs/                   # Detailed documentation
```

## Prerequisites

- Google Cloud CLI (`gcloud`) installed and authenticated
- Terraform installed
- GCP projects created for each environment

## Security

- Service account key: `terraform-key.json` (excluded from git)
- Shared across all environments
- Minimal required permissions

## Support

For detailed guides, see the `docs/` directory:

- `docs/README-setup.md` - Initial setup
- `docs/README-cost-optimization.md` - Cost management
- `docs/README-secrets.md` - Secret management
- `docs/README-cluster-access.md` - Cluster access
