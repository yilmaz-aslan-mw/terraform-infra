#!/bin/bash

# Automated Cluster Scheduling
# This script can be used with cron to automatically start/stop your cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_ID="vunapay-core-dev"
CLUSTER_NAME="my-gke-cluster"
REGION="us-central1"
NODE_POOL_NAME="lowcost-pool"

# Function to scale down
scale_down() {
    echo -e "${GREEN}💰 Scaling down cluster for cost savings...${NC}"
    gcloud container clusters resize $CLUSTER_NAME \
        --node-pool=$NODE_POOL_NAME \
        --num-nodes=0 \
        --region=$REGION \
        --quiet
    echo -e "${GREEN}✅ Cluster scaled down at $(date)${NC}"
}

# Function to scale up
scale_up() {
    echo -e "${GREEN}🚀 Scaling up cluster for development...${NC}"
    gcloud container clusters resize $CLUSTER_NAME \
        --node-pool=$NODE_POOL_NAME \
        --num-nodes=1 \
        --region=$REGION \
        --quiet
    echo -e "${GREEN}✅ Cluster scaled up at $(date)${NC}"
}

# Check if gcloud is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo -e "${RED}❌ You are not authenticated with gcloud. Please run: gcloud auth login${NC}"
    exit 1
fi

# Set project
gcloud config set project $PROJECT_ID

# Get cluster credentials
gcloud container clusters get-credentials $CLUSTER_NAME --region=$REGION

# Check command line argument
case "$1" in
    "up"|"start")
        scale_up
        ;;
    "down"|"stop")
        scale_down
        ;;
    *)
        echo -e "${YELLOW}Usage: $0 {up|down|start|stop}${NC}"
        echo -e "${YELLOW}  up/start   - Scale up cluster to 1 node${NC}"
        echo -e "${YELLOW}  down/stop  - Scale down cluster to 0 nodes${NC}"
        echo ""
        echo -e "${YELLOW}📅 For automated scheduling, add to crontab:${NC}"
        echo -e "${YELLOW}   # Start cluster at 9 AM on weekdays${NC}"
        echo -e "${YELLOW}   0 9 * * 1-5 /path/to/schedule-cluster.sh up${NC}"
        echo -e "${YELLOW}   # Stop cluster at 6 PM on weekdays${NC}"
        echo -e "${YELLOW}   0 18 * * 1-5 /path/to/schedule-cluster.sh down${NC}"
        echo -e "${YELLOW}   # Stop cluster at 6 PM on weekends${NC}"
        echo -e "${YELLOW}   0 18 * * 0,6 /path/to/schedule-cluster.sh down${NC}"
        exit 1
        ;;
esac 