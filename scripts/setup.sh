#!/bin/bash

# Environment Setup Script
# This script sets up infrastructure for a specific environment (dev, stage, prod)

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID=""
ENVIRONMENT=""
SERVICE_ACCOUNT_NAME="terraform-sa"
SKIP_SERVICE_ACCOUNT=false
SKIP_BACKEND_SETUP=false
SKIP_APIS=false

# Function to print usage
print_usage() {
    echo -e "${BLUE}Usage:${NC}"
    echo -e "  $0 --project-id <PROJECT_ID> --environment <ENVIRONMENT> [options]"
    echo ""
    echo -e "${BLUE}Required Arguments:${NC}"
    echo -e "  --project-id         GCP Project ID (e.g., vunapay-core-dev)"
    echo -e "  --environment        Environment name (dev, stage, prod)"
    echo ""
    echo -e "${BLUE}Optional Arguments:${NC}"
    echo -e "  --service-account    Service account name (default: terraform-sa)"
    echo -e "  --skip-sa            Skip service account creation"
    echo -e "  --skip-backend       Skip backend setup"
    echo -e "  --skip-apis          Skip API enablement"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo -e "  $0 --project-id ya-test-project-1-dev --environment dev"
    echo -e "  $0 --project-id ya-test-project-1-stage --environment stage"
    echo -e "  $0 --project-id ya-test-project-1-prod --environment prod"
}

# Function to validate environment
validate_environment() {
    local env="$1"
    case "$env" in
        dev|stage|prod)
            return 0
            ;;
        *)
            echo -e "${RED}❌ Invalid environment: $env${NC}"
            echo -e "${YELLOW}   Valid environments: dev, stage, prod${NC}"
            return 1
            ;;
    esac
}

# Function to setup service account
setup_service_account() {
    if [[ "$SKIP_SERVICE_ACCOUNT" == true ]]; then
        echo -e "${YELLOW}⚠️  Skipping service account creation${NC}"
        return
    fi
    
    echo -e "${GREEN}🔐 Setting up service account...${NC}"
    
    ./scripts/setup-service-account.sh \
        --project-id "$PROJECT_ID" \
        --service-account "$SERVICE_ACCOUNT_NAME"
    
    echo -e "${GREEN}✅ Service account setup complete${NC}"
    
    # Additional verification to ensure service account is fully propagated
    echo -e "${GREEN}🔍 Verifying service account propagation...${NC}"
    local full_sa_name="$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com"
    local max_attempts=15
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if gcloud iam service-accounts describe "$full_sa_name" --project="$PROJECT_ID" >/dev/null 2>&1; then
            # Test if we can actually use the service account for basic operations
            if gcloud projects get-iam-policy "$PROJECT_ID" --flatten="bindings[].members" --filter="bindings.members:$full_sa_name" --format="value(bindings.role)" >/dev/null 2>&1; then
                echo -e "${GREEN}✅ Service account is fully propagated and accessible${NC}"
                break
            else
                echo -e "${YELLOW}   Attempt $attempt/$max_attempts: Service account exists but not yet fully propagated, waiting...${NC}"
                sleep 5
                ((attempt++))
            fi
        else
            echo -e "${YELLOW}   Attempt $attempt/$max_attempts: Service account not yet available, waiting...${NC}"
            sleep 5
            ((attempt++))
        fi
    done
    
    if [[ $attempt -gt $max_attempts ]]; then
        echo -e "${RED}❌ Service account propagation verification failed after $max_attempts attempts${NC}"
        echo -e "${YELLOW}   The script will continue, but you may encounter issues with subsequent operations${NC}"
        echo -e "${YELLOW}   If you encounter permission errors, wait a few minutes and try again${NC}"
    fi
}

# Function to enable APIs
enable_apis() {
    if [[ "$SKIP_APIS" == true ]]; then
        echo -e "${YELLOW}⚠️  Skipping API enablement${NC}"
        return
    fi
    
    echo -e "${GREEN}🚀 Enabling required APIs...${NC}"
    
    ./scripts/setup-required-apis.sh \
        --project-id "$PROJECT_ID"
    
    echo -e "${GREEN}✅ API enablement complete${NC}"
    
    # Verify APIs are enabled
    echo -e "${GREEN}🔍 Verifying API enablement...${NC}"
    local required_apis=(
        "compute.googleapis.com"
        "container.googleapis.com"
        "sqladmin.googleapis.com"
        "servicenetworking.googleapis.com"
        "iam.googleapis.com"
        "cloudresourcemanager.googleapis.com"
    )
    
    local max_attempts=10
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        local disabled_apis=()
        for api in "${required_apis[@]}"; do
            if ! gcloud services list --enabled --filter="name:$api" --format="value(name)" | grep -q "$api"; then
                disabled_apis+=("$api")
            fi
        done
        
        if [[ ${#disabled_apis[@]} -eq 0 ]]; then
            echo -e "${GREEN}✅ All required APIs are enabled and ready${NC}"
            break
        else
            echo -e "${YELLOW}   Attempt $attempt/$max_attempts: Waiting for APIs to be fully enabled...${NC}"
            echo -e "${YELLOW}   Disabled APIs: ${disabled_apis[*]}${NC}"
            sleep 3
            ((attempt++))
        fi
    done
    
    if [[ $attempt -gt $max_attempts ]]; then
        echo -e "${YELLOW}⚠️  Some APIs may not be fully enabled yet${NC}"
        echo -e "${YELLOW}   The script will continue, but you may encounter API-related errors${NC}"
    fi
}

# Function to setup backend
setup_backend() {
    if [[ "$SKIP_BACKEND_SETUP" == true ]]; then
        echo -e "${YELLOW}⚠️  Skipping backend setup${NC}"
        return
    fi
    
    echo -e "${GREEN}🪣 Setting up Terraform backend...${NC}"
    
    ./scripts/setup-terraform-backend.sh \
        --project-id "$PROJECT_ID" \
        --environment "$ENVIRONMENT"
    
    # Copy the generated backend.tf to the environment directory
    if [[ -f "backend.tf" ]]; then
        cp backend.tf "envs/$ENVIRONMENT/backend.tf"
        echo -e "${GREEN}✅ Backend configuration copied to envs/$ENVIRONMENT/backend.tf${NC}"
    fi
    
    echo -e "${GREEN}✅ Backend setup complete${NC}"
}

# Function to setup Terraform
setup_terraform() {
    echo -e "${GREEN}🔧 Setting up Terraform...${NC}"
    
    # Change to environment directory
    local env_dir="envs/$ENVIRONMENT"
    if [[ ! -d "$env_dir" ]]; then
        echo -e "${RED}❌ Environment directory not found: $env_dir${NC}"
        exit 1
    fi
    
    cd "$env_dir"
    
    # Set up credentials using the dedicated script
    echo -e "${GREEN}🔐 Setting up authentication...${NC}"
    ../../scripts/setup-credentials.sh "$ENVIRONMENT" "$PROJECT_ID"
    echo -e "${GREEN}✅ Authentication configured${NC}"
    
    # Get the credentials file path
    local credentials_file="../../terraform-key.json"
    if [[ ! -f "$credentials_file" ]]; then
        echo -e "${RED}❌ Credentials file not found: $credentials_file${NC}"
        exit 1
    fi
    
    # Initialize Terraform with reconfigure flag for new backend setup
    echo -e "${GREEN}🔧 Initializing Terraform...${NC}"
    GOOGLE_APPLICATION_CREDENTIALS="$credentials_file" terraform init -reconfigure
    echo -e "${GREEN}✅ Terraform initialized${NC}"
    
    # Format Terraform code
    echo -e "${GREEN}📝 Formatting Terraform code...${NC}"
    terraform fmt
    echo -e "${GREEN}✅ Terraform code formatted${NC}"
    
    # Validate Terraform configuration
    echo -e "${GREEN}🔍 Validating Terraform configuration...${NC}"
    terraform validate
    echo -e "${GREEN}✅ Terraform configuration validated${NC}"
    
    # Go back to root
    cd ../..
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --project-id)
            PROJECT_ID="$2"
            shift 2
            ;;
        --environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --service-account)
            SERVICE_ACCOUNT_NAME="$2"
            shift 2
            ;;
        --skip-sa)
            SKIP_SERVICE_ACCOUNT=true
            shift
            ;;
        --skip-backend)
            SKIP_BACKEND_SETUP=true
            shift
            ;;
        --skip-apis)
            SKIP_APIS=true
            shift
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
if [[ -z "$PROJECT_ID" ]] || [[ -z "$ENVIRONMENT" ]]; then
    echo -e "${RED}❌ Project ID and Environment are required${NC}"
    print_usage
    exit 1
fi

# Validate environment
if ! validate_environment "$ENVIRONMENT"; then
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

echo -e "${GREEN}🚀 Starting Environment Setup...${NC}"
echo -e "${BLUE}Project ID:${NC} $PROJECT_ID"
echo -e "${BLUE}Environment:${NC} $ENVIRONMENT"
echo -e "${BLUE}Service Account:${NC} $SERVICE_ACCOUNT_NAME"
echo ""

# Set the project as active
echo -e "${GREEN}🔧 Setting project as active...${NC}"
gcloud config set project "$PROJECT_ID"
echo -e "${GREEN}✅ Project set as active${NC}"

# Create environment-specific tfvars file
ENV_DIR="envs/$ENVIRONMENT"
TFVARS_FILE="$ENV_DIR/${ENVIRONMENT}.tfvars"
SECRETS_FILE="$ENV_DIR/secrets.tfvars"

echo -e "${GREEN}📝 Creating tfvars file: $TFVARS_FILE${NC}"
mkdir -p "$ENV_DIR"

cat > "$TFVARS_FILE" << EOF
# ${ENVIRONMENT^} Environment Configuration
project_id  = "$PROJECT_ID"
region      = "us-central1"
environment = "$ENVIRONMENT"

# Infrastructure Configuration
node_count     = 1
machine_type   = "e2-small"
db_tier        = "db-f1-micro"

# Non-sensitive Configuration
api_base_url = "https://api-${ENVIRONMENT}.example.com"
log_level    = "debug"
EOF

echo -e "${GREEN}✅ tfvars file created successfully!${NC}"

# Create secrets template file
echo -e "${GREEN}📝 Creating secrets template: $SECRETS_FILE${NC}"
cat > "$SECRETS_FILE" << EOF
# ${ENVIRONMENT^} Environment Secrets
# ⚠️  DO NOT COMMIT THIS FILE TO VERSION CONTROL
# Copy this file and fill in your actual secret values

# Database Secrets
db_password = "your-${ENVIRONMENT}-db-password"

# API Secrets
api_key = "your-${ENVIRONMENT}-api-key"

# Authentication Secrets
clerk_secret_key = "your-${ENVIRONMENT}-clerk-secret-key"
jwt_secret       = "your-${ENVIRONMENT}-jwt-secret"

# External Service Secrets
stripe_secret_key = "your-${ENVIRONMENT}-stripe-secret-key"
redis_password    = "your-${ENVIRONMENT}-redis-password"
EOF

echo -e "${GREEN}✅ secrets template created successfully!${NC}"
echo -e "${YELLOW}⚠️  Remember to update $SECRETS_FILE with your actual secret values${NC}"

# Setup service account
setup_service_account

# Enable APIs
enable_apis

# Setup backend
setup_backend

# Setup Terraform
setup_terraform

echo ""
echo -e "${GREEN}🎉 Environment Setup Complete!${NC}"
echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo -e "${YELLOW}   1. Review the plan: cd envs/$ENVIRONMENT && terraform plan${NC}"
echo -e "${YELLOW}   2. Apply infrastructure: terraform apply${NC}"
echo -e "${YELLOW}   3. Destroy if needed: terraform destroy${NC}"
echo ""
echo -e "${BLUE}📋 Environment Details:${NC}"
echo -e "${BLUE}   Project ID:${NC} $PROJECT_ID"
echo -e "${BLUE}   Environment:${NC} $ENVIRONMENT"
echo -e "${BLUE}   Directory:${NC} envs/$ENVIRONMENT"
echo -e "${BLUE}   Backend:${NC} terraform-state-$PROJECT_ID"
echo ""
echo -e "${GREEN}✅ You can now proceed with Terraform operations!${NC}" 