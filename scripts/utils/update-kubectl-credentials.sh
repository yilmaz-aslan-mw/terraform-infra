#!/bin/bash

# Generic GKE Cluster Access Script
# This script provides cluster access information for any Kubernetes client
# Works with: kubectl, Lens, K9s, Portainer, Rancher, etc.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== GKE Cluster Access Information ===${NC}"
echo

# Get current project
PROJECT_ID=$(gcloud config get-value project)
echo -e "${GREEN}Current Project:${NC} $PROJECT_ID"

# Get cluster information
echo -e "${GREEN}Available Clusters:${NC}"
CLUSTERS=$(gcloud container clusters list --filter="location:us-central1" --format="table(name,location,masterVersion,numNodes,status)")

if [ -z "$CLUSTERS" ]; then
    echo -e "${RED}No clusters found in project $PROJECT_ID${NC}"
    exit 1
fi

echo "$CLUSTERS"

# Get the first available cluster name
CLUSTER_NAME=$(gcloud container clusters list --filter="location:us-central1" --format="value(name)" | head -1)

if [ -z "$CLUSTER_NAME" ]; then
    echo -e "${RED}No cluster name found${NC}"
    exit 1
fi

echo

# Get current kubectl context
CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "none")
echo -e "${GREEN}Current kubectl context:${NC} $CURRENT_CONTEXT"

echo

# Check if we need to update credentials
NEED_UPDATE=false

# Test cluster connectivity
echo -e "${GREEN}Testing cluster connectivity...${NC}"
if kubectl get nodes > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Cluster is accessible!${NC}"
else
    echo -e "${YELLOW}✗ Cannot access cluster. Updating credentials...${NC}"
    NEED_UPDATE=true
fi

# If context doesn't match current project, update credentials
if [[ "$CURRENT_CONTEXT" != *"$PROJECT_ID"* ]] || [ "$NEED_UPDATE" = true ]; then
    echo -e "${YELLOW}Context mismatch detected. Updating kubectl credentials...${NC}"
    echo -e "${GREEN}Getting credentials for cluster: $CLUSTER_NAME in project: $PROJECT_ID${NC}"
    
    gcloud container clusters get-credentials "$CLUSTER_NAME" --region us-central1 --project "$PROJECT_ID"
    
    echo -e "${GREEN}✓ Credentials updated successfully!${NC}"
    
    # Test connectivity again
    echo -e "${GREEN}Testing connectivity after update...${NC}"
    if kubectl get nodes > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Cluster is now accessible!${NC}"
    else
        echo -e "${RED}✗ Still cannot access cluster. Please check your authentication.${NC}"
        echo -e "${YELLOW}Try running: gcloud auth login${NC}"
        exit 1
    fi
fi

echo
echo -e "${GREEN}Cluster Nodes:${NC}"
kubectl get nodes

echo
echo -e "${CYAN}=== Connection Information for Any Kubernetes Client ===${NC}"
echo

# Get kubeconfig file location
KUBECONFIG_PATH="$HOME/.kube/config"
echo -e "${GREEN}Kubeconfig File Location:${NC}"
echo "$KUBECONFIG_PATH"
echo

# Get cluster details
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
CLUSTER_ENDPOINT=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CLUSTER_CA_CERT=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')

echo -e "${GREEN}Cluster Details:${NC}"
echo "- Name: $CLUSTER_NAME"
echo "- Endpoint: $CLUSTER_ENDPOINT"
echo "- Project: $PROJECT_ID"
echo "- Region: us-central1"
echo

# Get authentication info
AUTH_NAME=$(kubectl config view --minify -o jsonpath='{.users[0].name}')
echo -e "${GREEN}Authentication:${NC}"
echo "- Auth Method: $AUTH_NAME"
echo "- Kubeconfig: $KUBECONFIG_PATH"
echo

echo -e "${YELLOW}=== How to Connect with Different Clients ===${NC}"
echo

# Get updated context
UPDATED_CONTEXT=$(kubectl config current-context)

echo -e "${BLUE}1. kubectl (Command Line):${NC}"
echo "   kubectl config use-context $UPDATED_CONTEXT"
echo "   kubectl get nodes"
echo

echo -e "${BLUE}2. Lens Desktop:${NC}"
echo "   - Open Lens"
echo "   - Add cluster from kubeconfig: $KUBECONFIG_PATH"
echo "   - Or let Lens auto-detect the context"
echo

echo -e "${BLUE}3. K9s (Terminal UI):${NC}"
echo "   k9s --context $UPDATED_CONTEXT"
echo

echo -e "${BLUE}4. Portainer:${NC}"
echo "   - Add cluster using kubeconfig file"
echo "   - Upload: $KUBECONFIG_PATH"
echo

echo -e "${BLUE}5. Rancher:${NC}"
echo "   - Import cluster using kubeconfig"
echo "   - Use file: $KUBECONFIG_PATH"
echo

echo -e "${BLUE}6. Kubernetes Dashboard:${NC}"
echo "   kubectl proxy"
echo "   # Then access: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
echo

echo -e "${BLUE}7. Any Other Client:${NC}"
echo "   - Use kubeconfig file: $KUBECONFIG_PATH"
echo "   - Or set KUBECONFIG environment variable:"
echo "     export KUBECONFIG=$KUBECONFIG_PATH"
echo

echo -e "${CYAN}=== Useful Commands ===${NC}"
echo

echo -e "${GREEN}Get cluster credentials (if needed):${NC}"
echo "gcloud container clusters get-credentials $CLUSTER_NAME --region us-central1"
echo

echo -e "${GREEN}View all contexts:${NC}"
echo "kubectl config get-contexts"
echo

echo -e "${GREEN}Switch context:${NC}"
echo "kubectl config use-context <context-name>"
echo

echo -e "${GREEN}View current context details:${NC}"
echo "kubectl config view --minify"
echo

echo -e "${GREEN}Get cluster endpoint:${NC}"
echo "gcloud container clusters describe $CLUSTER_NAME --region us-central1 --format='value(endpoint)'"
echo

echo -e "${GREEN}Check cluster health:${NC}"
echo "kubectl get componentstatuses"
echo

echo -e "${GREEN}List all namespaces:${NC}"
echo "kubectl get namespaces"
echo

echo -e "${GREEN}Get cluster version:${NC}"
echo "kubectl version --short"
echo

echo -e "${CYAN}=== Troubleshooting ===${NC}"
echo

echo -e "${YELLOW}If you can't connect:${NC}"
echo "1. Check authentication: gcloud auth list"
echo "2. Re-authenticate: gcloud auth login"
echo "3. Get fresh credentials: gcloud container clusters get-credentials $CLUSTER_NAME --region us-central1"
echo "4. Check cluster status: gcloud container clusters describe $CLUSTER_NAME --region us-central1"
echo

echo -e "${GREEN}✓ Your cluster is ready to use with any Kubernetes client!${NC}" 