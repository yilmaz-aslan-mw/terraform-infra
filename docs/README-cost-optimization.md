# 💰 Cost Optimization Guide

This guide shows you how to optimize costs for your GKE infrastructure by stopping resources when not in use.

## 🎯 **Cost Breakdown**

### **Current Setup (24/7)**

| Resource                | Cost/Month | Can Stop?  |
| ----------------------- | ---------- | ---------- |
| GKE Cluster (e2-small)  | $12-15     | ✅ Yes     |
| Cloud SQL (db-f1-micro) | $7-15      | ⚠️ Partial |
| VPC/Networking          | $0-5       | ❌ No      |
| **Total**               | **$20-35** |            |

### **Optimized Setup (Night/Weekend)**

| Resource                | Cost/Month | Savings    |
| ----------------------- | ---------- | ---------- |
| GKE Cluster (0 nodes)   | $0         | $12-15     |
| Cloud SQL (db-f1-micro) | $7-15      | $0         |
| VPC/Networking          | $0-5       | $0         |
| **Total**               | **$7-20**  | **$13-15** |

**Potential savings: 40-60% per month!**

## 🚀 **Quick Start**

### **Manual Control**

```bash
# Scale down to save costs
./scripts/scale-down.sh

# Scale up when needed
./scripts/scale-up.sh
```

### **Automated Scheduling**

```bash
# Set up automated scheduling
./scripts/schedule-cluster.sh up    # Start cluster
./scripts/schedule-cluster.sh down  # Stop cluster
```

## 📅 **Automated Scheduling with Cron**

### **Set up cron jobs for automatic scheduling:**

```bash
# Edit crontab
crontab -e

# Add these lines for automated scheduling:
```

### **Weekday Schedule (9 AM - 6 PM)**

```bash
# Start cluster at 9 AM on weekdays
0 9 * * 1-5 /Users/yilmaznaciaslan/vunapay-infra/terraform-infra/scripts/schedule-cluster.sh up

# Stop cluster at 6 PM on weekdays
0 18 * * 1-5 /Users/yilmaznaciaslan/vunapay-infra/terraform-infra/scripts/schedule-cluster.sh down
```

### **Weekend Schedule (Always Off)**

```bash
# Stop cluster at 6 PM on weekends
0 18 * * 0,6 /Users/yilmaznaciaslan/vunapay-infra/terraform-infra/scripts/schedule-cluster.sh down
```

### **Custom Schedule Examples**

```bash
# Start at 8 AM, stop at 8 PM (12 hours/day)
0 8 * * 1-5 /path/to/scripts/schedule-cluster.sh up
0 20 * * 1-5 /path/to/scripts/schedule-cluster.sh down

# Only run Monday-Friday, 10 AM - 5 PM
0 10 * * 1-5 /path/to/scripts/schedule-cluster.sh up
0 17 * * 1-5 /path/to/scripts/schedule-cluster.sh down

# Keep running on weekends (remove weekend stop)
# 0 18 * * 0,6 /path/to/scripts/schedule-cluster.sh down
```

## 🔄 **What Happens When You Scale Down**

### **✅ What Stops (Cost Savings)**

- **GKE Compute Nodes**: $0 (was $12-15/month)
- **Container workloads**: Paused
- **Load balancer**: No traffic

### **⚠️ What Continues Running**

- **Cloud SQL**: Still running (~$7-15/month)
- **VPC Network**: Still exists (~$0-5/month)
- **Kubernetes control plane**: Still running (free tier)
- **Persistent volumes**: Still exist

### **🔄 What Happens When You Scale Up**

- **Nodes start**: 2-3 minutes
- **Pods restart**: 1-2 minutes
- **Services become available**: Immediately after pods ready
- **Database connection**: Re-established

## 💡 **Advanced Cost Optimization**

### **1. Cloud SQL Optimization**

```bash
# Stop Cloud SQL when not needed (takes 5-10 minutes to start)
gcloud sql instances patch my-postgres-instance --activation-policy NEVER

# Start Cloud SQL when needed
gcloud sql instances patch my-postgres-instance --activation-policy ALWAYS
```

### **2. Preemptible Nodes (Even Cheaper)**

Update your `main.tf` to use preemptible nodes:

```hcl
resource "google_container_node_pool" "lowcost_pool" {
  # ... existing config ...
  node_config {
    machine_type = "e2-small"
    preemptible  = true  # 60-80% cheaper but can be terminated
    # ... rest of config ...
  }
}
```

### **3. Spot Instances (Cheapest)**

```hcl
resource "google_container_node_pool" "spot_pool" {
  # ... existing config ...
  node_config {
    machine_type = "e2-small"
    spot         = true  # 90% cheaper but very unstable
    # ... rest of config ...
  }
}
```

## 📊 **Monitoring Costs**

### **Check Current Costs**

```bash
# View GCP billing
gcloud billing accounts list
gcloud billing projects describe vunapay-core-dev

# Check cluster status
gcloud container clusters describe my-gke-cluster --region=us-central1
```

### **Set Up Billing Alerts**

1. Go to [GCP Billing Console](https://console.cloud.google.com/billing)
2. Select your project
3. Go to "Budgets & alerts"
4. Create budget with alerts at $10, $20, $30

## 🚨 **Important Considerations**

### **⚠️ What You Lose When Scaled Down**

- **No application access**: Your Node.js app won't be accessible
- **No database access**: Can't connect to Cloud SQL from outside
- **Cold starts**: 2-3 minutes to get back online
- **No monitoring**: Limited visibility when stopped

### **✅ What You Keep**

- **Data**: All data is preserved
- **Configuration**: All K8s configs remain
- **Secrets**: Secret Manager access remains
- **Networking**: VPC and firewall rules intact

## 🎯 **Recommended Schedule**

### **For Development (Recommended)**

```bash
# Weekdays: 9 AM - 6 PM (9 hours/day)
# Weekends: Off
# Monthly cost: ~$15-20 (50% savings)
```

### **For Production**

```bash
# Always on (24/7)
# Monthly cost: ~$20-35
# Best for: Production workloads, monitoring, reliability
```

### **For Testing**

```bash
# Manual control only
# Scale up when testing, down when done
# Monthly cost: ~$7-15 (70% savings)
```

## 🔧 **Troubleshooting**

### **Common Issues**

1. **"Cluster not found"**

   ```bash
   # Check if cluster exists
   gcloud container clusters list --region=us-central1
   ```

2. **"Permission denied"**

   ```bash
   # Check authentication
   gcloud auth list
   gcloud config get-value project
   ```

3. **"Nodes not ready"**
   ```bash
   # Wait for nodes to be ready
   kubectl wait --for=condition=ready nodes --all --timeout=300s
   ```

### **Emergency Access**

If you need immediate access to a stopped cluster:

```bash
# Scale up immediately
./scripts/scale-up.sh

# Wait 2-3 minutes for nodes to be ready
kubectl get nodes
```

## 📈 **Cost Tracking**

### **Monthly Cost Tracker**

| Month | Hours Used | Cost | Savings |
| ----- | ---------- | ---- | ------- |
| Jan   | 24/7       | $30  | $0      |
| Feb   | 9h/day     | $15  | $15     |
| Mar   | Manual     | $10  | $20     |

### **Break-Even Analysis**

- **Setup cost**: $0 (using existing infrastructure)
- **Monthly savings**: $13-15
- **Break-even**: Immediate
- **Annual savings**: $156-180

## 🎉 **Summary**

**You can save 40-60% on your infrastructure costs** by scaling down your GKE cluster when not in use!

**Quick commands:**

- `./scripts/scale-down.sh` - Save money
- `./scripts/scale-up.sh` - Get back to work
- `./scripts/schedule-cluster.sh` - Automated scheduling

**Start saving today!** 💰
