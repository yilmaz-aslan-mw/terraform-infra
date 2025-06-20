# 🛠️ Scripts Directory

This directory contains all the automation scripts for managing your GKE infrastructure and applications.

## 📋 **Scripts Overview**

### **🚀 Infrastructure Setup Scripts**

| Script                       | Purpose                                            | Usage                                  |
| ---------------------------- | -------------------------------------------------- | -------------------------------------- |
| `enable-apis.sh`             | Enable required GCP APIs                           | `./scripts/enable-apis.sh`             |
| `setup-secrets.sh`           | Create secrets in Google Secret Manager            | `./scripts/setup-secrets.sh`           |
| `setup-workload-identity.sh` | Set up Workload Identity for Secret Manager access | `./scripts/setup-workload-identity.sh` |

### **💰 Cost Optimization Scripts**

| Script                | Purpose                                        | Usage                                      |
| --------------------- | ---------------------------------------------- | ------------------------------------------ |
| `scale-down.sh`       | Scale down GKE cluster to 0 nodes (save costs) | `./scripts/scale-down.sh`                  |
| `scale-up.sh`         | Scale up GKE cluster to 1 node (resume work)   | `./scripts/scale-up.sh`                    |
| `schedule-cluster.sh` | Automated cluster scheduling with cron         | `./scripts/schedule-cluster.sh {up\|down}` |

### **🚀 Application Deployment Scripts**

| Script          | Purpose                             | Usage                     |
| --------------- | ----------------------------------- | ------------------------- |
| `deploy-app.sh` | Build and deploy Node.js app to GKE | `./scripts/deploy-app.sh` |

## 🎯 **Quick Start Guide**

### **1. Initial Setup (One-time)**

```bash
# Enable required APIs
./scripts/enable-apis.sh

# Set up secrets management
./scripts/setup-secrets.sh
./scripts/setup-workload-identity.sh
```

### **2. Deploy Your Application**

```bash
# Deploy Node.js app to GKE
./scripts/deploy-app.sh
```

### **3. Cost Optimization**

```bash
# Scale down to save costs
./scripts/scale-down.sh

# Scale up when needed
./scripts/scale-up.sh

# Set up automated scheduling
crontab -e
# Add: 0 9 * * 1-5 ./scripts/schedule-cluster.sh up
# Add: 0 18 * * 1-5 ./scripts/schedule-cluster.sh down
```

## 📁 **Script Details**

### **🔧 Infrastructure Scripts**

#### **`enable-apis.sh`**

- **Purpose**: Enable all required GCP APIs for Terraform
- **APIs Enabled**: Compute, SQL, Container, Service Networking, IAM, Secret Manager
- **Usage**: Run once before using Terraform

#### **`setup-secrets.sh`**

- **Purpose**: Create secrets in Google Secret Manager
- **Secrets Created**: `db-password`, `api-key`, `jwt-secret`
- **Usage**: Run once to set up secret management

#### **`setup-workload-identity.sh`**

- **Purpose**: Set up Workload Identity for secure Secret Manager access
- **Creates**: GCP service account, IAM bindings, Workload Identity binding
- **Usage**: Run once to enable secure secret access from Kubernetes

### **💰 Cost Management Scripts**

#### **`scale-down.sh`**

- **Purpose**: Scale GKE cluster to 0 nodes to save costs
- **Savings**: ~$12-15/month
- **Recovery Time**: 2-3 minutes to scale back up

#### **`scale-up.sh`**

- **Purpose**: Scale GKE cluster back to 1 node for development
- **Wait Time**: 2-3 minutes for nodes to be ready
- **Verification**: Shows cluster status and pod information

#### **`schedule-cluster.sh`**

- **Purpose**: Automated cluster scheduling
- **Commands**: `up` (start), `down` (stop)
- **Cron Integration**: Can be used with crontab for automation

### **🚀 Deployment Scripts**

#### **`deploy-app.sh`**

- **Purpose**: Build and deploy Node.js application to GKE
- **Steps**: Build Docker image, push to registry, apply K8s manifests
- **Verification**: Shows deployment status and access information

## 🔧 **Configuration**

### **Project Settings**

All scripts use these default values:

- **Project ID**: `vunapay-core-dev`
- **Region**: `us-central1`
- **Cluster Name**: `my-gke-cluster`
- **Node Pool**: `lowcost-pool`

### **Customization**

To use different values, edit the variables at the top of each script:

```bash
PROJECT_ID="your-project-id"
REGION="your-region"
CLUSTER_NAME="your-cluster-name"
```

## 📅 **Automated Scheduling Examples**

### **Weekday Schedule (9 AM - 6 PM)**

```bash
# Add to crontab: crontab -e
0 9 * * 1-5 /path/to/scripts/schedule-cluster.sh up
0 18 * * 1-5 /path/to/scripts/schedule-cluster.sh down
```

### **Custom Schedule**

```bash
# 8 AM - 8 PM weekdays
0 8 * * 1-5 /path/to/scripts/schedule-cluster.sh up
0 20 * * 1-5 /path/to/scripts/schedule-cluster.sh down

# 10 AM - 5 PM weekdays only
0 10 * * 1-5 /path/to/scripts/schedule-cluster.sh up
0 17 * * 1-5 /path/to/scripts/schedule-cluster.sh down
```

## 🚨 **Troubleshooting**

### **Common Issues**

1. **"Permission denied"**

   ```bash
   # Make scripts executable
   chmod +x scripts/*.sh

   # Check gcloud authentication
   gcloud auth list
   ```

2. **"Cluster not found"**

   ```bash
   # Verify cluster exists
   gcloud container clusters list --region=us-central1
   ```

3. **"Script not found"**
   ```bash
   # Run from terraform-infra directory
   cd /path/to/terraform-infra
   ./scripts/script-name.sh
   ```

### **Debug Mode**

Add `set -x` to any script to see detailed execution:

```bash
# Edit script and add at the top
set -x
```

## 📊 **Cost Tracking**

### **Monthly Cost Tracker**

| Month | Usage Pattern | Cost | Savings |
| ----- | ------------- | ---- | ------- |
| Jan   | 24/7          | $30  | $0      |
| Feb   | 9h/day        | $15  | $15     |
| Mar   | Manual        | $10  | $20     |

### **Break-Even Analysis**

- **Setup cost**: $0
- **Monthly savings**: $13-15
- **Annual savings**: $156-180

## 🎯 **Best Practices**

1. **Run setup scripts once** before using other scripts
2. **Use automated scheduling** for consistent cost savings
3. **Monitor costs** with GCP billing alerts
4. **Test scripts** in a non-production environment first
5. **Keep scripts updated** with your project configuration

## 🔗 **Related Documentation**

- [`../README-cost-optimization.md`](../README-cost-optimization.md) - Detailed cost optimization guide
- [`../README-secrets.md`](../README-secrets.md) - Secret management guide
- [`../README-microservices.md`](../README-microservices.md) - Microservices deployment guide

## 🎉 **Quick Reference**

```bash
# Infrastructure setup
./scripts/enable-apis.sh
./scripts/setup-secrets.sh
./scripts/setup-workload-identity.sh

# Application deployment
./scripts/deploy-app.sh

# Cost optimization
./scripts/scale-down.sh    # Save money
./scripts/scale-up.sh      # Get back to work
./scripts/schedule-cluster.sh up    # Start cluster
./scripts/schedule-cluster.sh down  # Stop cluster
```

**All scripts are ready to use!** 🚀
