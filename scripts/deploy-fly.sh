#!/bin/bash
# HomeOS Fly.io Deployment Script
# This script deploys all HomeOS services to fly.io

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}   HomeOS Fly.io Deployment Script${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# Check if flyctl is installed
if ! command -v flyctl &> /dev/null && ! command -v ~/.fly/bin/flyctl &> /dev/null; then
    echo -e "${RED}Error: flyctl is not installed.${NC}"
    echo "Please install flyctl first:"
    echo "  curl -L https://fly.io/install.sh | sh"
    exit 1
fi

# Use flyctl from PATH or ~/.fly/bin
FLYCTL=$(command -v flyctl 2>/dev/null || echo "$HOME/.fly/bin/flyctl")

# Check if user is authenticated
if ! $FLYCTL auth whoami &> /dev/null; then
    echo -e "${YELLOW}You need to authenticate with fly.io first.${NC}"
    echo "Running: flyctl auth login"
    $FLYCTL auth login
fi

echo -e "${GREEN}Authenticated as: $($FLYCTL auth whoami)${NC}"
echo ""

# Function to deploy a service
deploy_service() {
    local service_name=$1
    local service_dir=$2

    echo -e "${YELLOW}Deploying $service_name...${NC}"
    cd "$service_dir"

    # Check if app exists, create if not
    if ! $FLYCTL apps list | grep -q "$service_name"; then
        echo "Creating app: $service_name"
        $FLYCTL apps create "$service_name" --org personal || true
    fi

    # Deploy
    $FLYCTL deploy --app "$service_name"

    echo -e "${GREEN}$service_name deployed successfully!${NC}"
    echo ""
}

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Deploy Infrastructure Services First
echo -e "${YELLOW}======================================${NC}"
echo -e "${YELLOW}Step 1: Setting up Managed Services${NC}"
echo -e "${YELLOW}======================================${NC}"
echo ""
echo "For production, you'll need to set up managed services:"
echo "  1. PostgreSQL: fly postgres create --name homeos-postgres"
echo "  2. Redis: Use Upstash Redis (free tier available)"
echo "  3. Temporal: Use Temporal Cloud or self-hosted"
echo ""
echo -e "${YELLOW}Press Enter to continue with deployment, or Ctrl+C to set up infrastructure first...${NC}"
read

# Set secrets for each service
echo -e "${YELLOW}======================================${NC}"
echo -e "${YELLOW}Step 2: Setting up Secrets${NC}"
echo -e "${YELLOW}======================================${NC}"
echo ""
echo "You need to set the following secrets for each app:"
echo "  - DATABASE_URL (PostgreSQL connection string)"
echo "  - REDIS_URL (Redis connection string)"
echo "  - JWT_SECRET (Random secret for JWT signing)"
echo "  - MASTER_ENCRYPTION_KEY (Control-plane secrets encryption key)"
echo "  - TEMPORAL_ADDRESS (Temporal server address)"
echo "  - TEMPORAL_NAMESPACE (Temporal namespace)"
echo "  - TEMPORAL_API_KEY (Temporal Cloud API key if used)"
echo "  - CONTROL_PLANE_SERVICE_TOKEN (Runtime/workflows internal auth)"
echo "  - RUNTIME_SERVICE_TOKEN (Workflows internal auth)"
echo "  - ANTHROPIC_API_KEY (For AI features)"
echo "  - MODAL_LLM_URL + MODAL_LLM_TOKEN (For private hosted LLM)"
echo ""
echo "Example commands:"
echo "  flyctl secrets set DATABASE_URL='postgres://...' --app homeos-control-plane"
echo "  flyctl secrets set JWT_SECRET='\$(openssl rand -hex 32)' --app homeos-control-plane"
echo ""
echo -e "${YELLOW}Press Enter to continue with deployment...${NC}"
read

# Deploy Control Plane
echo -e "${YELLOW}======================================${NC}"
echo -e "${YELLOW}Step 3: Deploying Services${NC}"
echo -e "${YELLOW}======================================${NC}"
echo ""

deploy_service "homeos-control-plane" "$PROJECT_ROOT/services/control-plane"
deploy_service "homeos-runtime" "$PROJECT_ROOT/services/runtime"
deploy_service "homeos-workflows" "$PROJECT_ROOT/services/workflows"

# Print deployment summary
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}   Deployment Complete!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo "Your services are now deployed:"
echo ""
echo "Control Plane API:"
$FLYCTL status --app homeos-control-plane 2>/dev/null | grep "Hostname:" || echo "  https://homeos-control-plane.fly.dev"
echo ""
echo "Runtime API:"
$FLYCTL status --app homeos-runtime 2>/dev/null | grep "Hostname:" || echo "  https://homeos-runtime.fly.dev"
echo ""
echo "Workflows Worker: (background worker - no HTTP endpoint)"
echo "  Check status: flyctl status --app homeos-workflows"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Set up secrets (DATABASE_URL, JWT_SECRET, etc.) for each app"
echo "2. Create PostgreSQL database: flyctl postgres create"
echo "3. Attach database to apps: flyctl postgres attach"
echo "4. Update iOS app with production URLs"
echo ""
echo "Useful commands:"
echo "  flyctl logs --app homeos-control-plane  # View logs"
echo "  flyctl status --app homeos-control-plane  # Check status"
echo "  flyctl secrets list --app homeos-control-plane  # List secrets"
