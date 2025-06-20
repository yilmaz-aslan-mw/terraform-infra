#!/bin/bash

# Scale Up GKE Cluster
# This script scales up your GKE cluster from zero nodes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Production protection
PRODUCTION_PROJECTS=("vunapay-core-prod" "vunapay-prod" "prod" "production")

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -p, --project PROJECT_ID     GCP Project ID (required)"
    echo "  -c, --cluster CLUSTER_NAME   GKE Cluster name (auto-detected if not specified)"
    echo "  -r, --region REGION          GCP Region (auto-detected if not specified)"
    echo "  -n, --node-pool POOL_NAME    Node pool name (auto-detected if not specified)"
    echo "  -s, --size NUM_NODES         Number of nodes to scale to (default: auto-detect)"
    echo "  -h, --help                   Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  PROJECT_ID                   GCP Project ID"
    echo "  CLUSTER_NAME                 GKE Cluster name"
    echo "  REGION                       GCP Region"
    echo "  NODE_POOL_NAME               Node pool name"
    echo "  NUM_NODES                    Number of nodes"
    echo ""
    echo "Examples:"
    echo "  $0 -p vunapay-core-stage                    # Auto-detect everything"
    echo "  $0 -p vunapay-core-dev                      # Auto-detect everything"
    echo "  $0 -p vunapay-core-prod                     # Auto-detect everything"
    echo "  $0 -p vunapay-core-stage -s 2               # Auto-detect + custom node count"
    echo "  $0 -p vunapay-core-stage -c custom-cluster  # Override cluster name"
    echo ""
    echo "ℹ️  Note: If --size is not specified, the script will auto-detect the original node count."
}

# Function to check if project is production
is_production_project() {
    local project_id="$1"
    for prod_project in "${PRODUCTION_PROJECTS[@]}"; do
        if [[ "$project_id" == *"$prod_project"* ]] || [[ "$project_id" == "$prod_project" ]]; then
            return 0  # true - is production
        fi
    done
    return 1  # false - not production
}

# Function to show production warning
show_production_warning() {
    local project_id="$1"
    echo ""
    echo -e "${YELLOW}⚠️  PRODUCTION ENVIRONMENT DETECTED ⚠️${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}Project: $project_id${NC}"
    echo -e "${YELLOW}Cluster: $CLUSTER_NAME${NC}"
    echo -e "${YELLOW}Region: $REGION${NC}"
    echo -e "${YELLOW}Target Nodes: $NUM_NODES${NC}"
    echo ""
    echo -e "${YELLOW}ℹ️  Scaling up production is generally safe, but:${NC}"
    echo -e "${YELLOW}   • Ensure you have proper monitoring in place${NC}"
    echo -e "${YELLOW}   • Verify this is the intended action${NC}"
    echo -e "${YELLOW}   • Consider the cost implications${NC}"
    echo ""
    echo -e "${YELLOW}Current time: $(date)${NC}"
    echo -e "${YELLOW}Current user: $(whoami)@$(hostname)${NC}"
    echo ""
    
    read -p "Press Enter to continue with production scaling, or Ctrl+C to abort: " -r
    echo ""
}

# Function to get original node count from Terraform state or cluster config
get_original_node_count() {
    local project_id="$1"
    local cluster_name="$2"
    local region="$3"
    local node_pool_name="$4"
    
    # Try to get from node pool configuration
    local original_count=$(gcloud container node-pools describe "$node_pool_name" \
        --cluster="$cluster_name" \
        --region="$region" \
        --project="$project_id" \
        --format="value(initialNodeCount)" 2>/dev/null || echo "")
    
    if [[ -n "$original_count" && "$original_count" != "None" ]]; then
        echo "$original_count"
    else
        # Fallback to default
        echo "1"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--project)
            PROJECT_ID="$2"
            shift 2
            ;;
        -c|--cluster)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -n|--node-pool)
            NODE_POOL_NAME="$2"
            shift 2
            ;;
        -s|--size)
            NUM_NODES="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
done

# Validate required PROJECT_ID
if [[ -z "$PROJECT_ID" ]]; then
    echo -e "${RED}❌ PROJECT_ID is required. Please provide it via:${NC}"
    echo -e "${YELLOW}   • Command line: $0 -p YOUR_PROJECT_ID${NC}"
    echo -e "${YELLOW}   • Environment variable: PROJECT_ID=YOUR_PROJECT_ID $0${NC}"
    echo -e "${YELLOW}   • Or see help: $0 --help${NC}"
    exit 1
fi

# Auto-detect cluster information if not provided
if [[ -z "$CLUSTER_NAME" ]] || [[ -z "$REGION" ]] || [[ -z "$NODE_POOL_NAME" ]]; then
    echo -e "${GREEN}🔍 Auto-detecting cluster information...${NC}"
    
    # Get the first available cluster
    CLUSTER_INFO=$(gcloud container clusters list --project="$PROJECT_ID" --format="table(name,location,status)" --filter="status:RUNNING" --limit=1)
    
    if [[ -z "$CLUSTER_INFO" ]] || [[ "$CLUSTER_INFO" == *"No resources found"* ]]; then
        echo -e "${RED}❌ No running clusters found in project '$PROJECT_ID'${NC}"
        exit 1
    fi
    
    # Extract cluster name and region
    CLUSTER_NAME=$(echo "$CLUSTER_INFO" | tail -n +2 | awk '{print $1}')
    REGION=$(echo "$CLUSTER_INFO" | tail -n +2 | awk '{print $2}')
    
    if [[ -z "$CLUSTER_NAME" ]] || [[ -z "$REGION" ]]; then
        echo -e "${RED}❌ Could not auto-detect cluster information${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Found cluster: $CLUSTER_NAME in region: $REGION${NC}"
    
    # Get the first available node pool
    NODE_POOL_INFO=$(gcloud container node-pools list --cluster="$CLUSTER_NAME" --region="$REGION" --project="$PROJECT_ID" --format="table(name,initialNodeCount,status)" --filter="status:RUNNING" --limit=1)
    
    if [[ -z "$NODE_POOL_INFO" ]] || [[ "$NODE_POOL_INFO" == *"No resources found"* ]]; then
        echo -e "${RED}❌ No running node pools found in cluster '$CLUSTER_NAME'${NC}"
        exit 1
    fi
    
    # Extract node pool name
    NODE_POOL_NAME=$(echo "$NODE_POOL_INFO" | tail -n +2 | awk '{print $1}')
    
    if [[ -z "$NODE_POOL_NAME" ]]; then
        echo -e "${RED}❌ Could not auto-detect node pool information${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Found node pool: $NODE_POOL_NAME${NC}"
fi

# Check if project is production
if is_production_project "$PROJECT_ID"; then
    show_production_warning "$PROJECT_ID"
fi

# Get original node count if not specified
if [[ -z "$NUM_NODES" ]]; then
    echo -e "${GREEN}🔍 Detecting original node count...${NC}"
    ORIGINAL_COUNT=$(get_original_node_count "$PROJECT_ID" "$CLUSTER_NAME" "$REGION" "$NODE_POOL_NAME")
    NUM_NODES="$ORIGINAL_COUNT"
    echo -e "${YELLOW}   • Original node count: $ORIGINAL_COUNT${NC}"
fi

echo -e "${GREEN}🚀 Scaling up GKE cluster...${NC}"
echo -e "${YELLOW}📋 Configuration:${NC}"
echo -e "${YELLOW}   • Project: $PROJECT_ID${NC}"
echo -e "${YELLOW}   • Cluster: $CLUSTER_NAME${NC}"
echo -e "${YELLOW}   • Region: $REGION${NC}"
echo -e "${YELLOW}   • Node Pool: $NODE_POOL_NAME${NC}"
echo -e "${YELLOW}   • Target Nodes: $NUM_NODES${NC}"
echo ""

# Check if gcloud is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo -e "${RED}❌ You are not authenticated with gcloud. Please run: gcloud auth login${NC}"
    exit 1
fi

# Check if user has access to the project
echo -e "${GREEN}🔍 Checking project access...${NC}"
if ! gcloud projects describe "$PROJECT_ID" >/dev/null 2>&1; then
    echo -e "${RED}❌ You don't have access to project '$PROJECT_ID' or it doesn't exist.${NC}"
    echo -e "${YELLOW}   Current account: $(gcloud config get-value account)${NC}"
    echo -e "${YELLOW}   Please check your permissions or switch to the correct account.${NC}"
    exit 1
fi

# Set project
echo -e "${GREEN}🔧 Setting project to $PROJECT_ID...${NC}"
gcloud config set project "$PROJECT_ID"

# Check if cluster exists
echo -e "${GREEN}🔍 Checking if cluster exists...${NC}"
if ! gcloud container clusters describe "$CLUSTER_NAME" --region="$REGION" >/dev/null 2>&1; then
    echo -e "${RED}❌ Cluster '$CLUSTER_NAME' not found in region '$REGION' in project '$PROJECT_ID'.${NC}"
    echo -e "${YELLOW}   Available clusters:${NC}"
    gcloud container clusters list --region="$REGION" --format="table(name,location,status)" || true
    exit 1
fi

# Get cluster credentials
echo -e "${GREEN}🔐 Getting cluster credentials...${NC}"
gcloud container clusters get-credentials "$CLUSTER_NAME" --region="$REGION"

# Check if node pool exists
echo -e "${GREEN}🔍 Checking if node pool exists...${NC}"
if ! gcloud container node-pools describe "$NODE_POOL_NAME" --cluster="$CLUSTER_NAME" --region="$REGION" >/dev/null 2>&1; then
    echo -e "${RED}❌ Node pool '$NODE_POOL_NAME' not found in cluster '$CLUSTER_NAME'.${NC}"
    echo -e "${YELLOW}   Available node pools:${NC}"
    gcloud container node-pools list --cluster="$CLUSTER_NAME" --region="$REGION" --format="table(name,config.machineType,version,status)" || true
    exit 1
fi

# Scale up node pool
echo -e "${GREEN}📈 Scaling up node pool to $NUM_NODES nodes...${NC}"
gcloud container clusters resize "$CLUSTER_NAME" \
    --node-pool="$NODE_POOL_NAME" \
    --num-nodes="$NUM_NODES" \
    --region="$REGION" \
    --quiet

echo -e "${GREEN}✅ Cluster scaled up successfully!${NC}"
echo ""
echo -e "${YELLOW}💰 Cost Impact:${NC}"
echo -e "${YELLOW}   • GKE compute costs: ~$12-15/month (was $0/month)${NC}"
echo -e "${YELLOW}   • Cloud SQL: Still running (~$7-15/month)${NC}"
echo -e "${YELLOW}   • Total cost: ~$19-30/month${NC}"
echo ""
echo -e "${YELLOW}📝 To scale back down:${NC}"
echo -e "${YELLOW}   ./scale-down.sh -p $PROJECT_ID${NC}"
echo ""
echo -e "${GREEN}🎉 Your cluster is now ready for development!${NC}" 