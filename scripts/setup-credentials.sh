#!/bin/bash

# Setup script for Terraform credentials
# Usage: ./setup-credentials.sh [environment] [project-id]

set -e

ENVIRONMENT=${1:-dev}
PROJECT_ID=${2:-""}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CREDENTIALS_FILE="$PROJECT_ROOT/terraform-key.json"

echo "🔐 Setting up Terraform credentials for $ENVIRONMENT environment"

# Check if credentials file exists
if [ ! -f "$CREDENTIALS_FILE" ]; then
    echo "❌ Error: terraform-key.json not found at $CREDENTIALS_FILE"
    echo "Please run the service account setup script first:"
    if [ -n "$PROJECT_ID" ]; then
        echo "./scripts/setup-service-account.sh --project-id $PROJECT_ID"
    else
        echo "./scripts/setup-service-account.sh --project-id <YOUR_PROJECT_ID>"
    fi
    exit 1
fi

# Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS="$CREDENTIALS_FILE"

echo "✅ Credentials set up successfully"
echo "📁 Credentials file: $CREDENTIALS_FILE"
echo "🔑 Environment variable: GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_APPLICATION_CREDENTIALS"

# Verify credentials work
echo "🔍 Testing credentials..."
gcloud auth activate-service-account --key-file="$CREDENTIALS_FILE" --quiet

echo "✅ Credentials are valid!"
echo ""
echo "🚀 You can now run Terraform commands:"
echo "   terraform plan"
echo "   terraform apply"
echo "   terraform destroy"
echo ""
echo "💡 To use these credentials in a new shell, run:"
echo "   export GOOGLE_APPLICATION_CREDENTIALS=\"$CREDENTIALS_FILE\"" 