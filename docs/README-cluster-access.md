# GKE Cluster Access Guide

This guide provides generic instructions for accessing your GKE cluster with any Kubernetes client.

## Prerequisites

- Google Cloud SDK (`gcloud`) installed and authenticated
- kubectl installed
- Access to the GKE cluster

## Quick Access

### 1. Get Cluster Credentials

```bash
# Navigate to your Terraform environment
cd terraform-infra/envs/dev

# Get cluster credentials
gcloud container clusters get-credentials stage-gke-cluster --region us-central1
```

### 2. Verify Access

```bash
# Test cluster connectivity
kubectl cluster-info

# List nodes
kubectl get nodes

# List namespaces
kubectl get namespaces
```

## Cluster Information

- **Cluster Name**: `stage-gke-cluster`
- **Project**: `vunapay-core-stage`
- **Region**: `us-central1`
- **Control Plane**: `https://34.44.9.94`
- **Kubeconfig**: `~/.kube/config`

## Access Methods

### Command Line (kubectl)

```bash
# Use current context
kubectl config use-context gke_vunapay-core-stage_us-central1_stage-gke-cluster

# Basic commands
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get services --all-namespaces
```

### Desktop Applications

#### Lens

1. Open Lens Desktop
2. Add cluster from kubeconfig: `~/.kube/config`
3. Or let Lens auto-detect the context

#### K9s (Terminal UI)

```bash
k9s --context gke_vunapay-core-stage_us-central1_stage-gke-cluster
```

#### Portainer

1. Add cluster using kubeconfig file
2. Upload: `~/.kube/config`

#### Rancher

1. Import cluster using kubeconfig
2. Use file: `~/.kube/config`

### Web Interfaces

#### Kubernetes Dashboard

```bash
# Start proxy
kubectl proxy

# Access dashboard
# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

#### GKE Console

- Go to [Google Cloud Console](https://console.cloud.google.com)
- Navigate to Kubernetes Engine
- Select your cluster: `stage-gke-cluster`

## Environment Variables

```bash
# Set kubeconfig path
export KUBECONFIG=~/.kube/config

# Set context
export KUBECTL_CONTEXT=gke_vunapay-core-stage_us-central1_stage-gke-cluster
```

## Useful Commands

### Cluster Management

```bash
# Get cluster details
gcloud container clusters describe stage-gke-cluster --region us-central1

# Scale cluster
gcloud container clusters resize stage-gke-cluster --region us-central1 --num-nodes=3

# Update cluster
gcloud container clusters upgrade stage-gke-cluster --region us-central1
```

### kubectl Commands

```bash
# View all contexts
kubectl config get-contexts

# Switch context
kubectl config use-context <context-name>

# View current context
kubectl config view --minify

# Get cluster version
kubectl version --short

# Check cluster health
kubectl get componentstatuses
```

### Application Management

```bash
# Deploy application
kubectl apply -f deployment.yaml

# View deployments
kubectl get deployments --all-namespaces

# View pods
kubectl get pods --all-namespaces

# View services
kubectl get services --all-namespaces

# View ingress
kubectl get ingress --all-namespaces
```

## Troubleshooting

### Authentication Issues

```bash
# Check authentication
gcloud auth list

# Re-authenticate
gcloud auth login

# Get fresh credentials
gcloud container clusters get-credentials stage-gke-cluster --region us-central1
```

### Connection Issues

```bash
# Check cluster status
gcloud container clusters describe stage-gke-cluster --region us-central1

# Check firewall rules
gcloud compute firewall-rules list

# Check IAM permissions
gcloud projects get-iam-policy vunapay-core-stage
```

### Common Errors

1. **"cluster not found"**

   - Verify cluster name and region
   - Check if cluster exists: `gcloud container clusters list`

2. **"permission denied"**

   - Check IAM roles: `gcloud projects get-iam-policy vunapay-core-stage`
   - Ensure you have `container.clusters.get` permission

3. **"connection refused"**
   - Check if cluster is running
   - Verify network connectivity
   - Check firewall rules

## Security Best Practices

1. **Use Service Accounts**: Create dedicated service accounts for applications
2. **RBAC**: Implement proper role-based access control
3. **Network Policies**: Configure network policies for pod-to-pod communication
4. **Secrets Management**: Use Kubernetes secrets or external secret managers
5. **Regular Updates**: Keep cluster and node pools updated

## Cost Optimization

1. **Node Pool Scaling**: Use autoscaling for node pools
2. **Preemptible Nodes**: Use preemptible nodes for non-critical workloads
3. **Resource Limits**: Set proper resource requests and limits
4. **Cluster Scheduling**: Use cluster scheduling scripts for dev environments

## Automation Scripts

Use the provided scripts in the `scripts/` directory:

```bash
# Generic cluster access information
bash scripts/access-cluster-generic.sh

# Scale cluster up/down
bash scripts/scale-up.sh
bash scripts/scale-down.sh

# Schedule cluster operations
bash scripts/schedule-cluster.sh
```

## Support

For issues related to:

- **Terraform**: Check the Terraform documentation
- **GKE**: Refer to [GKE documentation](https://cloud.google.com/kubernetes-engine/docs)
- **kubectl**: Check [kubectl documentation](https://kubernetes.io/docs/reference/kubectl/)
