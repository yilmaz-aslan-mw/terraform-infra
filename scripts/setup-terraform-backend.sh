#!/bin/bash

# Terraform Backend Setup Script for GCS
# This script creates a GCS bucket for Terraform state management

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID=""
BUCKET_NAME=""
LOCATION="us-central1"
ENVIRONMENT="dev"

# Function to print usage
print_usage() {
    echo -e "${BLUE}Usage:${NC}"
    echo -e "  $0 --project-id <PROJECT_ID> [options]"
    echo ""
    echo -e "${BLUE}Required Arguments:${NC}"
    echo -e "  --project-id         GCP Project ID"
    echo ""
    echo -e "${BLUE}Optional Arguments:${NC}"
    echo -e "  --bucket-name        GCS bucket name (auto-generated if not provided)"
    echo -e "  --location          GCS bucket location (default: us-central1)"
    echo -e "  --environment       Environment name (default: dev)"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo -e "  $0 --project-id my-terraform-project-123"
    echo -e "  $0 --project-id my-terraform-project-123 --bucket-name my-terraform-state"
}

# Function to generate bucket name
generate_bucket_name() {
    local project_id="$1"
    local environment="$2"
    # Convert to lowercase and replace dots with hyphens
    local clean_project=$(echo "$project_id" | tr '[:upper:]' '[:lower:]' | sed 's/\./-/g')
    # Add timestamp to ensure uniqueness
    local timestamp=$(date +%s | tail -c 6)
    echo "terraform-state-${clean_project}-${environment}-${timestamp}"
}

# Function to create GCS bucket
create_gcs_bucket() {
    local project_id="$1"
    local bucket_name="$2"
    local location="$3"
    
    echo -e "${GREEN}🪣 Creating GCS bucket...${NC}"
    
    # Check if bucket already exists
    if gcloud storage buckets describe "gs://$bucket_name" --project="$project_id" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Bucket gs://$bucket_name already exists${NC}"
        read -p "Do you want to use the existing bucket? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${RED}❌ Setup cancelled${NC}"
            exit 1
        fi
    else
        # Create bucket first
        gcloud storage buckets create "gs://$bucket_name" \
            --project="$project_id" \
            --location="$location"
        echo -e "${GREEN}✅ GCS bucket created successfully${NC}"
    fi
    
    # Enable versioning
    echo -e "${GREEN}📝 Enabling versioning...${NC}"
    gcloud storage buckets update "gs://$bucket_name" --versioning
    echo -e "${GREEN}✅ Versioning enabled${NC}"
    
    # Set uniform bucket-level access
    echo -e "${GREEN}🔒 Setting uniform bucket-level access...${NC}"
    gcloud storage buckets update "gs://$bucket_name" --uniform-bucket-level-access
    echo -e "${GREEN}✅ Uniform bucket-level access enabled${NC}"
    
    # Set lifecycle policy to delete old versions after 90 days
    echo -e "${GREEN}🗑️  Setting lifecycle policy...${NC}"
    cat > /tmp/lifecycle.json << EOF
{
  "rule": [
    {
      "action": {"type": "Delete"},
      "condition": {
        "age": 90,
        "isLive": false
      }
    }
  ]
}
EOF
    gcloud storage buckets update "gs://$bucket_name" --lifecycle-file=/tmp/lifecycle.json
    rm /tmp/lifecycle.json
    echo -e "${GREEN}✅ Lifecycle policy set${NC}"
}

# Function to create backend configuration
create_backend_config() {
    local bucket_name="$1"
    local environment="$2"
    
    echo -e "${GREEN}📄 Creating backend configuration...${NC}"
    
    # Create backend.tf file
    cat > backend.tf << EOF
terraform {
  backend "gcs" {
    bucket = "$bucket_name"
    prefix = "terraform/state/$environment"
  }
}
EOF
    
    echo -e "${GREEN}✅ Backend configuration created: backend.tf${NC}"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --project-id)
            PROJECT_ID="$2"
            shift 2
            ;;
        --bucket-name)
            BUCKET_NAME="$2"
            shift 2
            ;;
        --location)
            LOCATION="$2"
            shift 2
            ;;
        --environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$PROJECT_ID" ]]; then
    echo -e "${RED}❌ Project ID is required${NC}"
    print_usage
    exit 1
fi

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI is not installed. Please install it first.${NC}"
    echo -e "${YELLOW}Installation guide: https://cloud.google.com/sdk/docs/install${NC}"
    exit 1
fi

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo -e "${YELLOW}⚠️  You are not authenticated with gcloud. Please run: gcloud auth login${NC}"
    exit 1
fi

echo -e "${GREEN}🚀 Starting Terraform Backend Setup...${NC}"
echo -e "${BLUE}Project ID:${NC} $PROJECT_ID"
echo -e "${BLUE}Location:${NC} $LOCATION"
echo -e "${BLUE}Environment:${NC} $ENVIRONMENT"

# Set the project as active
echo -e "${GREEN}🔧 Setting project as active...${NC}"
gcloud config set project "$PROJECT_ID"
echo -e "${GREEN}✅ Project set as active${NC}"

# Generate bucket name if not provided
if [[ -z "$BUCKET_NAME" ]]; then
    BUCKET_NAME=$(generate_bucket_name "$PROJECT_ID" "$ENVIRONMENT")
    echo -e "${GREEN}📋 Generated Bucket Name: $BUCKET_NAME${NC}"
else
    echo -e "${GREEN}📋 Using provided Bucket Name: $BUCKET_NAME${NC}"
fi

# Create GCS bucket
create_gcs_bucket "$PROJECT_ID" "$BUCKET_NAME" "$LOCATION"

# Create backend configuration
create_backend_config "$BUCKET_NAME" "$ENVIRONMENT"

# Create output file with backend details
OUTPUT_FILE="terraform-backend-setup-$(date +%Y%m%d-%H%M%S).env"
cat > "$OUTPUT_FILE" << EOF
# Terraform Backend Setup Details
# Generated on: $(date)
PROJECT_ID=$PROJECT_ID
BUCKET_NAME=$BUCKET_NAME
LOCATION=$LOCATION
ENVIRONMENT=$ENVIRONMENT

# Export these variables for use in other scripts
export PROJECT_ID=$PROJECT_ID
export BUCKET_NAME=$BUCKET_NAME
export LOCATION=$LOCATION
export ENVIRONMENT=$ENVIRONMENT

# Backend configuration details
BACKEND_BUCKET=gs://$BUCKET_NAME
BACKEND_PREFIX=terraform/state/$ENVIRONMENT
EOF

echo -e "${GREEN}📄 Backend details saved to: $OUTPUT_FILE${NC}"

echo ""
echo -e "${GREEN}🎉 Terraform Backend Setup Complete!${NC}"
echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo -e "${YELLOW}   1. Set authentication: export GOOGLE_APPLICATION_CREDENTIALS=\"\$(pwd)/terraform-key.json\"${NC}"
echo -e "${YELLOW}   2. Initialize Terraform: terraform init${NC}"
echo -e "${YELLOW}   3. Plan deployment: terraform plan${NC}"
echo -e "${YELLOW}   4. Apply infrastructure: terraform apply${NC}"
echo ""
echo -e "${BLUE}📋 Backend Details:${NC}"
echo -e "${BLUE}   Project ID:${NC} $PROJECT_ID"
echo -e "${BLUE}   Bucket:${NC} gs://$BUCKET_NAME"
echo -e "${BLUE}   Location:${NC} $LOCATION"
echo -e "${BLUE}   Environment:${NC} $ENVIRONMENT"
echo -e "${BLUE}   State Prefix:${NC} terraform/state/$ENVIRONMENT"
echo ""
echo -e "${GREEN}✅ You can now proceed with Terraform initialization!${NC}" 