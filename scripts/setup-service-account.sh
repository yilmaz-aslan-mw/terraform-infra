#!/bin/bash

# GCP Service Account Setup Script for Terraform
# This script creates a service account with necessary permissions for Terraform

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID=""
SERVICE_ACCOUNT_NAME="terraform-sa"
SERVICE_ACCOUNT_DISPLAY_NAME="Terraform Service Account"
KEY_FILE=""  # Will be auto-generated based on project ID

# Function to print usage
print_usage() {
    echo -e "${BLUE}Usage:${NC}"
    echo -e "  $0 --project-id <PROJECT_ID> [options]"
    echo ""
    echo -e "${BLUE}Required Arguments:${NC}"
    echo -e "  --project-id         GCP Project ID"
    echo ""
    echo -e "${BLUE}Optional Arguments:${NC}"
    echo -e "  --service-account    Service account name (default: terraform-sa)"
    echo -e "  --display-name       Service account display name (default: Terraform Service Account)"
    echo -e "  --key-file          Output key file name (default: auto-generated with project ID)"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo -e "  $0 --project-id my-terraform-project-123"
    echo -e "  $0 --project-id my-terraform-project-123 --service-account my-terraform-sa"
    echo -e "  $0 --project-id my-terraform-project-123 --key-file custom-key.json"
}

# Function to generate key file name
generate_key_file_name() {
    local project_id="$1"
    local custom_key_file="$2"
    
    if [[ -n "$custom_key_file" ]]; then
        echo "$custom_key_file"
    else
        # Convert project ID to a safe filename
        local safe_project_id=$(echo "$project_id" | sed 's/[^a-zA-Z0-9._-]/-/g')
        echo "terraform-key-${safe_project_id}.json"
    fi
}

# Function to check if project exists
check_project() {
    local project_id="$1"
    if ! gcloud projects describe "$project_id" >/dev/null 2>&1; then
        echo -e "${RED}❌ Project $project_id does not exist or you don't have access${NC}"
        exit 1
    fi
}

# Function to create service account
create_service_account() {
    local project_id="$1"
    local sa_name="$2"
    local display_name="$3"
    
    local full_sa_name="$sa_name@$project_id.iam.gserviceaccount.com"
    
    # Check if service account already exists
    if gcloud iam service-accounts describe "$full_sa_name" --project="$project_id" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Service account $full_sa_name already exists${NC}"
        read -p "Do you want to use the existing service account? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${RED}❌ Setup cancelled${NC}"
            exit 1
        fi
    else
        # Create service account
        echo -e "${GREEN}👤 Creating service account...${NC}"
        gcloud iam service-accounts create "$sa_name" \
            --display-name="$display_name" \
            --description="Service account for Terraform infrastructure management" \
            --project="$project_id" \
            --quiet
        echo -e "${GREEN}✅ Service account created successfully${NC}"
        
        # Wait for service account to be fully propagated
        echo -e "${GREEN}⏳ Waiting for service account to be fully available...${NC}"
        local max_attempts=10
        local attempt=1
        
        while [[ $attempt -le $max_attempts ]]; do
            if gcloud iam service-accounts describe "$full_sa_name" --project="$project_id" >/dev/null 2>&1; then
                echo -e "${GREEN}✅ Service account is now available${NC}"
                break
            else
                echo -e "${YELLOW}   Attempt $attempt/$max_attempts: Service account not yet available, waiting...${NC}"
                sleep 3
                ((attempt++))
            fi
        done
        
        if [[ $attempt -gt $max_attempts ]]; then
            echo -e "${RED}❌ Service account creation verification failed after $max_attempts attempts${NC}"
            echo -e "${YELLOW}   Please try running the script again in a few moments${NC}"
            exit 1
        fi
    fi
}

# Function to assign IAM roles
assign_roles() {
    local project_id="$1"
    local sa_name="$2"
    local full_sa_name="$sa_name@$project_id.iam.gserviceaccount.com"
    
    echo -e "${GREEN}🔐 Assigning IAM roles...${NC}"
    
    # Verify service account exists before proceeding
    if ! gcloud iam service-accounts describe "$full_sa_name" --project="$project_id" >/dev/null 2>&1; then
        echo -e "${RED}❌ Service account $full_sa_name does not exist. Cannot assign roles.${NC}"
        exit 1
    fi
    
    # Required roles for Terraform infrastructure
    ROLES=(
        "roles/resourcemanager.projectIamAdmin"        # Project IAM Admin (CRITICAL for Terraform)
        "roles/iam.serviceAccountAdmin"               # Service Account Admin
        "roles/iam.serviceAccountUser"                # Service Account User
        "roles/cloudsql.admin"                        # Cloud SQL Admin
        "roles/compute.admin"                         # Compute Admin
        "roles/container.admin"                       # Kubernetes Admin
        "roles/artifactregistry.admin"                # Artifact Registry Admin Create and manage repositories and artifacts.
        "roles/storage.admin"                         # Storage Admin
        "roles/servicenetworking.networksAdmin"       # Service Networking Admin
        "roles/secretmanager.admin"                   # Secret Manager Admin
    )
    
    for role in "${ROLES[@]}"; do
        echo -e "${GREEN}   🔑 Assigning: $role${NC}"
        
        # Add retry logic for role assignment
        local max_attempts=3
        local attempt=1
        local success=false
        
        while [[ $attempt -le $max_attempts && $success == false ]]; do
            if gcloud projects add-iam-policy-binding "$project_id" \
                --member="serviceAccount:$full_sa_name" \
                --role="$role" \
                --quiet >/dev/null 2>&1; then
                success=true
            else
                echo -e "${YELLOW}     Attempt $attempt/$max_attempts failed, retrying...${NC}"
                sleep 2
                ((attempt++))
            fi
        done
        
        if [[ $success == false ]]; then
            echo -e "${RED}❌ Failed to assign role $role after $max_attempts attempts${NC}"
            echo -e "${YELLOW}   You may need to assign this role manually${NC}"
        else
            echo -e "${GREEN}     ✅ Role assigned successfully${NC}"
            # Small delay to allow IAM propagation
            sleep 1
        fi
    done
    
    echo -e "${GREEN}✅ All roles assigned successfully${NC}"
    
    # Verify role assignments
    echo -e "${GREEN}🔍 Verifying role assignments...${NC}"
    local max_attempts=10
    local attempt=1
    local all_roles_assigned=true
    
    while [[ $attempt -le $max_attempts ]]; do
        local missing_roles=()
        for role in "${ROLES[@]}"; do
            if ! gcloud projects get-iam-policy "$project_id" \
                --flatten="bindings[].members" \
                --filter="bindings.members:$full_sa_name AND bindings.role:$role" \
                --format="value(bindings.role)" | grep -q "$role"; then
                missing_roles+=("$role")
            fi
        done
        
        if [[ ${#missing_roles[@]} -eq 0 ]]; then
            echo -e "${GREEN}✅ All roles verified and properly assigned${NC}"
            break
        else
            echo -e "${YELLOW}   Attempt $attempt/$max_attempts: Waiting for roles to propagate...${NC}"
            echo -e "${YELLOW}   Missing roles: ${missing_roles[*]}${NC}"
            sleep 3
            ((attempt++))
        fi
    done
    
    if [[ $attempt -gt $max_attempts ]]; then
        echo -e "${YELLOW}⚠️  Some roles may not be fully propagated yet${NC}"
        echo -e "${YELLOW}   The script will continue, but you may need to wait a few minutes for full access${NC}"
    fi
}

# Function to create service account key
create_service_account_key() {
    local project_id="$1"
    local sa_name="$2"
    local key_file="$3"
    local full_sa_name="$sa_name@$project_id.iam.gserviceaccount.com"
    
    echo -e "${GREEN}🔑 Creating service account key...${NC}"
    
    # Verify service account exists before creating key
    if ! gcloud iam service-accounts describe "$full_sa_name" --project="$project_id" >/dev/null 2>&1; then
        echo -e "${RED}❌ Service account $full_sa_name does not exist. Cannot create key.${NC}"
        exit 1
    fi
    
    # Create key file with retry logic
    local max_attempts=3
    local attempt=1
    local success=false
    
    while [[ $attempt -le $max_attempts && $success == false ]]; do
        if gcloud iam service-accounts keys create "$key_file" \
            --iam-account="$full_sa_name" \
            --project="$project_id" \
            --quiet >/dev/null 2>&1; then
            success=true
        else
            echo -e "${YELLOW}   Attempt $attempt/$max_attempts failed, retrying...${NC}"
            sleep 2
            ((attempt++))
        fi
    done
    
    if [[ $success == false ]]; then
        echo -e "${RED}❌ Failed to create service account key after $max_attempts attempts${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Service account key created: $key_file${NC}"
    
    # Set proper permissions on key file
    chmod 600 "$key_file"
    echo -e "${GREEN}✅ Key file permissions set to 600${NC}"
}

# Parse command line arguments
CUSTOM_KEY_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --project-id)
            PROJECT_ID="$2"
            shift 2
            ;;
        --service-account)
            SERVICE_ACCOUNT_NAME="$2"
            shift 2
            ;;
        --display-name)
            SERVICE_ACCOUNT_DISPLAY_NAME="$2"
            shift 2
            ;;
        --key-file)
            CUSTOM_KEY_FILE="$2"
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

# Generate key file name
KEY_FILE=$(generate_key_file_name "$PROJECT_ID" "$CUSTOM_KEY_FILE")

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

echo -e "${GREEN}🚀 Starting Service Account Setup...${NC}"
echo -e "${BLUE}Project ID:${NC} $PROJECT_ID"
echo -e "${BLUE}Service Account:${NC} $SERVICE_ACCOUNT_NAME"
echo -e "${BLUE}Display Name:${NC} $SERVICE_ACCOUNT_DISPLAY_NAME"
echo -e "${BLUE}Key File:${NC} $KEY_FILE"

# Check if project exists
echo -e "${GREEN}🔍 Checking project...${NC}"
check_project "$PROJECT_ID"
echo -e "${GREEN}✅ Project exists and is accessible${NC}"

# Set the project as active
echo -e "${GREEN}🔧 Setting project as active...${NC}"
gcloud config set project "$PROJECT_ID"
echo -e "${GREEN}✅ Project set as active${NC}"

# Create service account
create_service_account "$PROJECT_ID" "$SERVICE_ACCOUNT_NAME" "$SERVICE_ACCOUNT_DISPLAY_NAME"

# Assign IAM roles
assign_roles "$PROJECT_ID" "$SERVICE_ACCOUNT_NAME"

# Create service account key
create_service_account_key "$PROJECT_ID" "$SERVICE_ACCOUNT_NAME" "$KEY_FILE"

echo ""
echo -e "${GREEN}🎉 Service Account Setup Complete!${NC}"
echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo -e "${YELLOW}   1. Set up Terraform backend: ./setup-terraform-backend.sh${NC}"
echo -e "${YELLOW}   2. Set authentication: export GOOGLE_APPLICATION_CREDENTIALS=\"\$(pwd)/$KEY_FILE\"${NC}"
echo -e "${YELLOW}   3. Initialize Terraform: terraform init${NC}"
echo -e "${YELLOW}   4. Plan deployment: terraform plan${NC}"
echo -e "${YELLOW}   5. Apply infrastructure: terraform apply${NC}"
echo ""
echo -e "${BLUE}📋 Service Account Details:${NC}"
echo -e "${BLUE}   Project ID:${NC} $PROJECT_ID"
echo -e "${BLUE}   Service Account:${NC} $SERVICE_ACCOUNT_NAME"
echo -e "${BLUE}   Email:${NC} $SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com"
echo -e "${BLUE}   Key File:${NC} $KEY_FILE"
echo ""
echo -e "${GREEN}✅ You can now proceed with the next steps!${NC}" 