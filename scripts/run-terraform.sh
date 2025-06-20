#!/bin/bash

# Terraform Runner Script
# This script runs Terraform commands with proper authentication

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=""
COMMAND=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CREDENTIALS_FILE="$PROJECT_ROOT/terraform-key.json"

# Function to print usage
print_usage() {
    echo -e "${BLUE}Usage:${NC}"
    echo -e "  $0 --environment <ENVIRONMENT> --command <COMMAND> [terraform-args...]"
    echo ""
    echo -e "${BLUE}Required Arguments:${NC}"
    echo -e "  --environment        Environment name (dev, stage, prod)"
    echo -e "  --command           Terraform command (plan, apply, destroy, etc.)"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo -e "  $0 --environment dev --command plan"
    echo -e "  $0 --environment stage --command apply"
    echo -e "  $0 --environment prod --command destroy"
    echo -e "  $0 --environment dev --command output"
    echo ""
    echo -e "${BLUE}Available Commands:${NC}"
    echo -e "  plan     - Show execution plan"
    echo -e "  apply    - Apply changes"
    echo -e "  destroy  - Destroy infrastructure"
    echo -e "  output   - Show outputs"
    echo -e "  show     - Show state"
    echo -e "  refresh  - Refresh state"
    echo -e "  validate - Validate configuration"
    echo -e "  fmt      - Format code"
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

# Parse command line arguments
TERRAFORM_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --command)
            COMMAND="$2"
            shift 2
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        *)
            TERRAFORM_ARGS+=("$1")
            shift
            ;;
    esac
done

# Validate required arguments
if [[ -z "$ENVIRONMENT" ]]; then
    echo -e "${RED}❌ Environment is required${NC}"
    print_usage
    exit 1
fi

if [[ -z "$COMMAND" ]]; then
    echo -e "${RED}❌ Command is required${NC}"
    print_usage
    exit 1
fi

# Validate environment
if ! validate_environment "$ENVIRONMENT"; then
    exit 1
fi

# Check if credentials file exists
if [[ ! -f "$CREDENTIALS_FILE" ]]; then
    echo -e "${RED}❌ Credentials file not found: $CREDENTIALS_FILE${NC}"
    echo -e "${YELLOW}Please run the setup script first:${NC}"
    echo -e "${YELLOW}  ./scripts/setup.sh --project-id <PROJECT_ID> --environment $ENVIRONMENT${NC}"
    exit 1
fi

# Check if environment directory exists
ENV_DIR="$PROJECT_ROOT/envs/$ENVIRONMENT"
if [[ ! -d "$ENV_DIR" ]]; then
    echo -e "${RED}❌ Environment directory not found: $ENV_DIR${NC}"
    echo -e "${YELLOW}Please run the setup script first:${NC}"
    echo -e "${YELLOW}  ./scripts/setup.sh --project-id <PROJECT_ID> --environment $ENVIRONMENT${NC}"
    exit 1
fi

echo -e "${GREEN}🚀 Running Terraform $COMMAND for $ENVIRONMENT environment...${NC}"
echo -e "${BLUE}Environment:${NC} $ENVIRONMENT"
echo -e "${BLUE}Command:${NC} $COMMAND"
echo -e "${BLUE}Directory:${NC} $ENV_DIR"
echo -e "${BLUE}Credentials:${NC} $CREDENTIALS_FILE"
echo ""

# Change to environment directory
cd "$ENV_DIR"

# Run Terraform command with credentials
echo -e "${GREEN}🔧 Executing: terraform $COMMAND${NC}"
GOOGLE_APPLICATION_CREDENTIALS="$CREDENTIALS_FILE" terraform "$COMMAND" "${TERRAFORM_ARGS[@]}"

echo ""
echo -e "${GREEN}✅ Terraform $COMMAND completed successfully!${NC}" 