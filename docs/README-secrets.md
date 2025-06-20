# 🔐 Secret Management Guide

This guide explains how to properly manage secrets for your Node.js application using Google Secret Manager and Kubernetes.

## 🎯 **Overview: How Secret Management Works**

### **The Problem:**

- ❌ Hardcoded passwords in code
- ❌ Insecure Kubernetes secrets (base64 encoded)
- ❌ No version control for secrets
- ❌ No audit trail

### **The Solution:**

- ✅ Google Secret Manager as source of truth
- ✅ Workload Identity for secure access
- ✅ Encrypted secrets at rest
- ✅ Version control and audit logging

## 🏗️ **Architecture**

```
Node.js App (K8s Pod)
    ↓ (Workload Identity)
GCP Service Account
    ↓ (IAM)
Google Secret Manager
    ↓
Encrypted Secrets (Database Password, API Keys, etc.)
```

## 📋 **Step-by-Step Implementation**

### **Step 1: Create Secrets in Google Secret Manager**

```bash
# Run the setup script
chmod +x scripts/setup-secrets.sh
./scripts/setup-secrets.sh
```

This creates:

- `db-password` - Database password
- `api-key` - API key for external services
- `jwt-secret` - JWT signing secret

### **Step 2: Set Up Workload Identity**

```bash
# Run the Workload Identity setup
chmod +x scripts/setup-workload-identity.sh
./scripts/setup-workload-identity.sh
```

This creates:

- GCP Service Account with Secret Manager access
- Workload Identity binding
- IAM permissions

### **Step 3: Apply Kubernetes Resources**

```bash
# Apply service account and RBAC
kubectl apply -f k8s-manifests/service-account.yaml

# Apply updated deployment
kubectl apply -f k8s-manifests/deployment-with-secrets.yaml
```

### **Step 4: Update Your Application**

1. **Install Secret Manager client:**

   ```bash
   cd app
   npm install @google-cloud/secret-manager
   ```

2. **Use the updated server code:**
   ```bash
   cp server-with-secrets.js server.js
   ```

## 🔍 **How It Works**

### **1. Secret Retrieval Process**

```javascript
// Your app requests a secret
const dbPassword = await getSecret('db-password');

// Secret Manager returns the encrypted value
// Workload Identity provides authentication
// No service account keys needed!
```

### **2. Security Benefits**

- ✅ **No service account keys** in pods
- ✅ **Automatic rotation** of secrets
- ✅ **Audit logging** of secret access
- ✅ **Fine-grained permissions**

### **3. Fallback Mechanism**

```javascript
// If Secret Manager fails, fall back to env vars
const secret = (await getSecret('db-password')) || process.env.DB_PASSWORD;
```

## 🧪 **Testing Your Setup**

### **1. Test Secret Access**

```bash
# Port forward to your app
kubectl port-forward service/nodejs-app-service 8080:80 -n vunapay-apps

# Test secrets endpoint
curl http://localhost:8080/api/secrets
```

**Expected Response:**

```json
{
  "message": "Secrets retrieved successfully",
  "secrets": {
    "database": "available",
    "apiKey": "available",
    "jwtSecret": "available"
  }
}
```

### **2. Test Database Connection**

```bash
# Test database connectivity
curl http://localhost:8080/ready
```

## 🔄 **Secret Management Workflow**

### **Adding New Secrets**

1. **Create in Secret Manager:**

   ```bash
   echo -n "new-secret-value" | gcloud secrets create new-secret --data-file=-
   ```

2. **Update your app:**

   ```javascript
   const newSecret = await getSecret('new-secret');
   ```

3. **Redeploy app:**
   ```bash
   kubectl rollout restart deployment/nodejs-app -n vunapay-apps
   ```

### **Updating Existing Secrets**

1. **Update in Secret Manager:**

   ```bash
   echo -n "new-password" | gcloud secrets versions add db-password --data-file=-
   ```

2. **Restart app to pick up new version:**
   ```bash
   kubectl rollout restart deployment/nodejs-app -n vunapay-apps
   ```

## 🚨 **Troubleshooting**

### **Common Issues**

1. **"Permission denied" accessing secrets**

   ```bash
   # Check Workload Identity binding
   gcloud iam service-accounts get-iam-policy nodejs-app-sa@vunapay-core-dev.iam.gserviceaccount.com
   ```

2. **"Secret not found"**

   ```bash
   # List available secrets
   gcloud secrets list

   # Check secret exists
   gcloud secrets describe db-password
   ```

3. **"Database connection failed"**

   ```bash
   # Check if Cloud SQL is ready
   gcloud sql instances describe my-postgres-instance

   # Check VPC peering
   gcloud compute networks peerings list --network=my-vpc-network
   ```

### **Debug Commands**

```bash
# Check pod logs
kubectl logs -f deployment/nodejs-app -n vunapay-apps

# Check service account
kubectl describe serviceaccount nodejs-app-sa -n vunapay-apps

# Test secret access from pod
kubectl exec -it <pod-name> -n vunapay-apps -- curl http://localhost:3000/api/secrets
```

## 📊 **Monitoring and Auditing**

### **Secret Access Logs**

```bash
# View Secret Manager audit logs
gcloud logging read "resource.type=secretmanager.googleapis.com/Secret"
```

### **Workload Identity Logs**

```bash
# View Workload Identity logs
gcloud logging read "resource.type=gke_cluster"
```

## 🔒 **Security Best Practices**

1. **Principle of Least Privilege**

   - Only grant necessary permissions
   - Use specific IAM roles

2. **Secret Rotation**

   - Rotate secrets regularly
   - Use versioned secrets

3. **Access Monitoring**

   - Monitor secret access
   - Set up alerts for unusual access

4. **Network Security**
   - Use private VPC for database
   - Restrict network access

## 🎯 **Next Steps**

1. **Test the complete setup**
2. **Add more secrets as needed**
3. **Set up monitoring and alerts**
4. **Implement secret rotation**
5. **Add more microservices**

Your secret management is now production-ready! 🚀
