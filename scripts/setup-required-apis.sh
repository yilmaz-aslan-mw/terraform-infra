#!/bin/bash

# Enable Required GCP APIs for Terraform Setup
# This script enables only the minimal set of APIs needed for the initial infrastructure

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Usage
print_usage() {
    echo -e "${GREEN}Usage:${NC} $0 --project-id <PROJECT_ID>"
    echo -e "  --project-id   GCP Project ID (required)"
    echo -e "  --help         Show this help message"
}

# Parse arguments
PROJECT_ID=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --project-id)
            PROJECT_ID="$2"
            shift 2
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
    esac
done

if [[ -z "$PROJECT_ID" ]]; then
    echo -e "${RED}❌ Project ID is required${NC}"
    print_usage
    exit 1
fi

# Check gcloud
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI is not installed.${NC}"
    exit 1
fi

# Check authentication
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo -e "${YELLOW}⚠️  Not authenticated. Run: gcloud auth login${NC}"
    exit 1
fi

# Set project
echo -e "${GREEN}🔧 Setting project: $PROJECT_ID${NC}"
gcloud config set project "$PROJECT_ID"

# Minimal required APIs
REQUIRED_APIS=(
    "compute.googleapis.com"           # Compute Engine API
    "container.googleapis.com"         # Kubernetes Engine API
    "sqladmin.googleapis.com"          # Cloud SQL Admin API
    "servicenetworking.googleapis.com" # Service Networking API
    "iam.googleapis.com"               # IAM
    "cloudresourcemanager.googleapis.com" # Cloud Resource Manager API
    "containerregistry.googleapis.com"    # Google Container Registry API
    "secretmanager.googleapis.com"        # Secret Manager API
)

echo -e "${GREEN}🚀 Enabling required APIs...${NC}"
for api in "${REQUIRED_APIS[@]}"; do
    echo -e "${GREEN}   📦 Enabling: $api${NC}"
    gcloud services enable "$api" --quiet
done

echo -e "${GREEN}✅ All required APIs enabled for project: $PROJECT_ID${NC}" 