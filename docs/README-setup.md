# Terraform Service Account Setup

This guide will help you set up a service account with the necessary permissions for your Terraform infrastructure deployment.

## Prerequisites

1. **Google Cloud CLI (gcloud)** installed
2. **Authenticated** with gcloud (`gcloud auth login`)
3. **Project ID** ready

## Required GCP APIs

Before running Terraform, you need to enable these APIs in your GCP project:

### Core APIs (Required)

```bash
# Compute Engine API - for VPC, subnets, firewall rules, global addresses
gcloud services enable compute.googleapis.com

# Cloud SQL Admin API - for PostgreSQL instances, databases, users
gcloud services enable sqladmin.googleapis.com

# Kubernetes Engine API - for GKE clusters and node pools
gcloud services enable container.googleapis.com

# Service Networking API - for VPC peering connections
gcloud services enable servicenetworking.googleapis.com

# Identity and Access Management (IAM) API - for service account management
gcloud services enable iam.googleapis.com

# Cloud Resource Manager API - for project-level operations
gcloud services enable cloudresourcemanager.googleapis.com
```

### Optional APIs (Recommended)

```bash
# Secret Manager API - for secure password storage
gcloud services enable secretmanager.googleapis.com

# Cloud Build API - for container image building (if needed)
gcloud services enable cloudbuild.googleapis.com

# Container Registry API - for Docker image storage
gcloud services enable containerregistry.googleapis.com
```

### One-Liner to Enable All Required APIs

```bash
gcloud services enable \
  compute.googleapis.com \
  sqladmin.googleapis.com \
  container.googleapis.com \
  servicenetworking.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com \
  secretmanager.googleapis.com
```

## Quick Setup

### Step 1: Enable Required APIs

Run the one-liner above to enable all necessary APIs.

### Step 2: Update the Project ID

Edit the `setup-service-account.sh` script and replace `your-project-id` with your actual GCP project ID:

```bash
PROJECT_ID="your-actual-project-id"
```

### Step 3: Run the Setup Script

```bash
cd terraform-infra
./setup-service-account.sh
```

### Step 4: Set Environment Variable

After the script completes, set the credentials environment variable:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="./terraform-key.json"
```

## What the Script Does

The script automatically:

1. ✅ Creates a service account named `terraform-service-account`
2. ✅ Assigns all necessary IAM roles:
   - **Compute Engine Admin** - for VPC, subnets, firewall rules
   - **Cloud SQL Admin** - for PostgreSQL instances and databases
   - **Kubernetes Engine Admin** - for GKE clusters and node pools
   - **Service Networking Admin** - for VPC peering
   - **Service Account User** - for GKE node pools
   - **Secret Manager Secret Accessor** - for secure password management
3. ✅ Downloads the service account key as `terraform-key.json`

## Security Best Practices

### 1. Add to .gitignore

Add the service account key to your `.gitignore`:

```bash
echo "terraform-key.json" >> .gitignore
```

### 2. Use Secret Manager (Recommended)

Instead of hardcoded passwords in your Terraform config, use Google Secret Manager:

```hcl
# In your main.tf, replace the hardcoded password with:
resource "google_sql_user" "users" {
  name     = "dbuser"
  instance = google_sql_database_instance.postgres_instance.name
  password = data.google_secret_manager_secret_version.db_password.secret_data
}

data "google_secret_manager_secret_version" "db_password" {
  secret  = "db-password"
  version = "latest"
}
```

### 3. Production Considerations

For production environments, consider:

- Using **Workload Identity** instead of service account keys
- Implementing **least privilege** access with custom roles
- Using **Terraform Cloud** or **GitHub Actions** with secure credential management

## Manual Commands (Alternative)

If you prefer to run commands manually:

```bash
# Set your project ID
PROJECT_ID="your-project-id"
SERVICE_ACCOUNT_EMAIL="terraform-service-account@${PROJECT_ID}.iam.gserviceaccount.com"

# Create service account
gcloud iam service-accounts create terraform-service-account \
    --display-name="Terraform Infrastructure Manager"

# Assign roles
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
    --role="roles/compute.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
    --role="roles/cloudsql.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
    --role="roles/container.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
    --role="roles/servicenetworking.networksAdmin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
    --role="roles/iam.serviceAccountUser"

# Create key
gcloud iam service-accounts keys create terraform-key.json \
    --iam-account=$SERVICE_ACCOUNT_EMAIL
```

## Troubleshooting

### Common Issues

1. **"Permission denied"** - Make sure you're authenticated and have Owner/Editor permissions
2. **"Service account already exists"** - This is normal, the script handles it gracefully
3. **"Project not found"** - Verify your project ID is correct
4. **"API not enabled"** - Run the API enablement commands above

### Verify Setup

Check that the service account was created and roles were assigned:

```bash
# List service accounts
gcloud iam service-accounts list

# Check IAM bindings
gcloud projects get-iam-policy YOUR_PROJECT_ID \
    --flatten="bindings[].members" \
    --format="table(bindings.role)" \
    --filter="bindings.members:terraform-service-account"

# Check enabled APIs
gcloud services list --enabled --filter="name:compute.googleapis.com OR name:sqladmin.googleapis.com OR name:container.googleapis.com"
```

## Next Steps

After setting up the service account:

1. Run `terraform init` to initialize your Terraform workspace
2. Run `terraform plan` to see what resources will be created
3. Run `terraform apply` to create your infrastructure

Happy deploying! 🚀

### Permissions

### API's to enable in GCP

- **Compute Engine API** (`compute.googleapis.com`) - Required for VPC, subnets, firewall rules, global addresses
- **Cloud SQL Admin API** (`sqladmin.googleapis.com`) - Required for PostgreSQL instances, databases, users
- **Kubernetes Engine API** (`container.googleapis.com`) - Required for GKE clusters and node pools
- **Service Networking API** (`servicenetworking.googleapis.com`) - Required for VPC peering connections
- **Identity and Access Management API** (`iam.googleapis.com`) - Required for service account management
- **Cloud Resource Manager API** (`cloudresourcemanager.googleapis.com`) - Required for project-level operations
- **Secret Manager API** (`secretmanager.googleapis.com`) - Recommended for secure password storage
