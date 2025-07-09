#!/bin/bash

# Scale Down GKE Cluster to Save Costs
# This script scales down your GKE cluster to zero nodes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -p, --project PROJECT_ID     GCP Project ID (required)"
    echo "  -c, --cluster CLUSTER_NAME   GKE Cluster name (auto-detected if not specified)"
    echo "  -r, --region REGION          GCP Region (auto-detected if not specified)"
    echo "  -n, --node-pool POOL_NAME    Node pool name (auto-detected if not specified)"
    echo "  -h, --help                   Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  PROJECT_ID                   GCP Project ID"
    echo "  CLUSTER_NAME                 GKE Cluster name"
    echo "  REGION                       GCP Region"
    echo "  NODE_POOL_NAME               Node pool name"
    echo ""
    echo "Examples:"
    echo "  $0 -p vunapay-core-stage                    # Auto-detect everything"
    echo "  $0 -p vunapay-core-dev                      # Auto-detect everything"
    echo "  $0 -p vunapay-core-prod                     # Auto-detect everything"
    echo "  $0 -p vunapay-core-stage -c custom-cluster  # Override cluster name"
    echo ""
    echo "⚠️  WARNING: Scaling down will cause service outages!"
}

# Function to auto-detect cluster information
auto_detect_cluster_info() {
    local project_id="$1"
    
    echo -e "${GREEN}🔍 Auto-detecting cluster information...${NC}"
    
    # Get the first available cluster
    local cluster_info=$(gcloud container clusters list --project="$project_id" --format="table(name,location,status)" --filter="status:RUNNING" --limit=1)
    
    if [[ -z "$cluster_info" ]] || [[ "$cluster_info" == *"No resources found"* ]]; then
        echo -e "${RED}❌ No running clusters found in project '$project_id'${NC}"
        exit 1
    fi
    
    # Extract cluster name and region
    local cluster_name=$(echo "$cluster_info" | tail -n +2 | awk '{print $1}')
    local region=$(echo "$cluster_info" | tail -n +2 | awk '{print $2}')
    
    if [[ -z "$cluster_name" ]] || [[ -z "$region" ]]; then
        echo -e "${RED}❌ Could not auto-detect cluster information${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Found cluster: $cluster_name in region: $region${NC}"
    
    # Get the first available node pool
    local node_pool_info=$(gcloud container node-pools list --cluster="$cluster_name" --region="$region" --project="$project_id" --format="table(name,initialNodeCount,status)" --filter="status:RUNNING" --limit=1)
    
    if [[ -z "$node_pool_info" ]] || [[ "$node_pool_info" == *"No resources found"* ]]; then
        echo -e "${RED}❌ No running node pools found in cluster '$cluster_name'${NC}"
        exit 1
    fi
    
    # Extract node pool name
    local node_pool_name=$(echo "$node_pool_info" | tail -n +2 | awk '{print $1}')
    
    if [[ -z "$node_pool_name" ]]; then
        echo -e "${RED}❌ Could not auto-detect node pool information${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Found node pool: $node_pool_name${NC}"
    
    # Return values
    echo "$cluster_name"
    echo "$region"
    echo "$node_pool_name"
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



echo -e "${GREEN}💰 Scaling down GKE cluster to save costs...${NC}"
echo -e "${YELLOW}📋 Configuration:${NC}"
echo -e "${YELLOW}   • Project: $PROJECT_ID${NC}"
echo -e "${YELLOW}   • Cluster: $CLUSTER_NAME${NC}"
echo -e "${YELLOW}   • Region: $REGION${NC}"
echo -e "${YELLOW}   • Node Pool: $NODE_POOL_NAME${NC}"
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

# Scale down node pool to 0
echo -e "${GREEN}📉 Scaling down node pool to 0 nodes...${NC}"
gcloud container clusters resize "$CLUSTER_NAME" \
    --node-pool="$NODE_POOL_NAME" \
    --num-nodes=0 \
    --region="$REGION" \
    --quiet

echo -e "${GREEN}✅ Cluster scaled down successfully!${NC}"
echo ""
echo -e "${YELLOW}💰 Cost Savings:${NC}"
echo -e "${YELLOW}   • GKE compute costs: $0/month (was ~$12-15/month)${NC}"
echo -e "${YELLOW}   • Cloud SQL: Still running (~$7-15/month)${NC}"
echo -e "${YELLOW}   • Total savings: ~$12-15/month${NC}"
echo ""
echo -e "${YELLOW}📝 To scale back up:${NC}"
echo -e "${YELLOW}   ./scale-up.sh -p $PROJECT_ID${NC}"
echo ""
echo -e "${GREEN}🎉 Your cluster is now cost-optimized!${NC}" 