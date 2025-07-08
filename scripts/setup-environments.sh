#!/bin/bash

# Environment Setup Script
# This script helps set up different environments (dev, stage, prod)
# Each environment uses a separate GCP project for complete isolation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[HEADER]${NC} $1"
}

# Check if required arguments are provided
if [ $# -lt 1 ]; then
    print_error "Usage: $0 <environment> [action]"
    print_error "Environment: dev, stage, prod"
    print_error "Action: plan, apply, destroy (default: apply)"
    print_error "Example: $0 dev apply"
    exit 1
fi

ENVIRONMENT=$1
ACTION=${2:-apply}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|stage|prod)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT"
    print_error "Valid environments: dev, stage, prod"
    exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    print_error "Invalid action: $ACTION"
    print_error "Valid actions: plan, apply, destroy"
    exit 1
fi

print_header "Setting up $ENVIRONMENT environment"

# Set project ID based on environment (separate projects for each)
case $ENVIRONMENT in
    dev)
        PROJECT_ID="ya-test-project-1-dev"
        ;;
    stage)
        PROJECT_ID="ya-test-project-1-stage"
        ;;
    prod)
        PROJECT_ID="ya-test-project-1-prod"
        ;;
esac

print_status "Using project: $PROJECT_ID"

# Check if gcloud is available
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud is not installed or not in PATH"
    exit 1
fi

# Check if terraform is available
if ! command -v terraform &> /dev/null; then
    print_error "terraform is not installed or not in PATH"
    exit 1
fi

# Set the project
print_status "Setting GCP project..."
gcloud config set project $PROJECT_ID

# Navigate to the environment directory
ENV_DIR="envs/$ENVIRONMENT"
if [ ! -d "$ENV_DIR" ]; then
    print_error "Environment directory not found: $ENV_DIR"
    exit 1
fi

cd "$ENV_DIR"

# Check for required files
if [ ! -f "main.tf" ]; then
    print_error "main.tf not found in $ENV_DIR"
    exit 1
fi

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
    print_status "Initializing Terraform..."
    terraform init
fi

# Check for production variables
if [ "$ENVIRONMENT" = "prod" ]; then
    if [ ! -f "prod.tfvars" ]; then
        print_warning "prod.tfvars not found. Please create it from prod.tfvars.example"
        print_status "Example: cp prod.tfvars.example prod.tfvars && edit prod.tfvars"
        exit 1
    fi
    TFVARS_FILE="prod.tfvars"
else
    TFVARS_FILE=""
fi

# Run Terraform command
print_status "Running Terraform $ACTION for $ENVIRONMENT environment..."

if [ "$ACTION" = "destroy" ]; then
    print_warning "This will destroy all resources in the $ENVIRONMENT environment!"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Destroy cancelled"
        exit 0
    fi
fi

if [ -n "$TFVARS_FILE" ]; then
    terraform $ACTION -var-file="$TFVARS_FILE"
else
    terraform $ACTION
fi

print_status "Terraform $ACTION completed for $ENVIRONMENT environment!"

# Post-deployment setup for Kubernetes
if [ "$ACTION" = "apply" ]; then
    print_status "Setting up Kubernetes access..."
    
    # Get GKE cluster credentials
    case $ENVIRONMENT in
        dev)
            CLUSTER_NAME="dev-gke-cluster"
            ;;
        stage)
            CLUSTER_NAME="stage-gke-cluster"
            ;;
        prod)
            CLUSTER_NAME="prod-gke-cluster"
            ;;
    esac
    
    print_status "Getting credentials for cluster: $CLUSTER_NAME"
    gcloud container clusters get-credentials $CLUSTER_NAME --region us-central1 --project $PROJECT_ID
    
    print_status "Kubernetes setup completed!"
    print_status "You can now run: ./scripts/setup.sh (from vunapay-k8s-deployments directory)"
fi

print_header "$ENVIRONMENT environment setup completed!" 