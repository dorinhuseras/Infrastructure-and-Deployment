#!/bin/bash

# Multi-environment Terraform deployment script
# Usage: ./deploy.sh <environment> <action>
# Examples:
#   ./deploy.sh myapp1 plan
#   ./deploy.sh myapp1 apply
#   ./deploy.sh myapp2 apply
#   ./deploy.sh myapp1 destroy

set -e

ENVIRONMENT=${1:-}
ACTION=${2:-plan}

# Plans directory
PLANS_DIR="tfplans"
mkdir -p "$PLANS_DIR"

# Plan file path
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validate inputs
if [ -z "$ENVIRONMENT" ]; then
    echo -e "${RED}Error: Environment name required${NC}"
    echo "Usage: $0 <environment> [plan|apply|destroy]"
    echo ""
    echo "Available environments:"
    ls -1 envs/*.tfvars 2>/dev/null | grep -v terraform.tfvars.example | xargs -n1 basename | sed 's/.tfvars//' || echo "  No environment files found"
    exit 1
fi

# Check if variable file exists
TFVARS_FILE="envs/${ENVIRONMENT}.tfvars"
if [ ! -f "$TFVARS_FILE" ]; then
    echo -e "${RED}Error: Variable file '${TFVARS_FILE}' not found${NC}"
    echo ""
    echo "Available environment files:"
    ls -1 envs/*.tfvars 2>/dev/null | grep -v terraform.tfvars.example | xargs -n1 basename | sed 's/.tfvars//' || echo "  No environment files found"
    exit 1
fi

echo -e "${YELLOW}========================================${NC}"
echo -e "${GREEN}Environment: ${ENVIRONMENT}${NC}"
echo -e "${GREEN}Action: ${ACTION}${NC}"
echo -e "${YELLOW}========================================${NC}"

# Create or switch to workspace
echo -e "${YELLOW}Setting up workspace...${NC}"
terraform workspace list | grep -q "$ENVIRONMENT" || terraform workspace new "$ENVIRONMENT"
terraform workspace select "$ENVIRONMENT"

# Execute Terraform action
case $ACTION in
    plan)
        echo -e "${YELLOW}Running terraform plan...${NC}"
        PLAN_FILE="${PLANS_DIR}/tfplan_${ENVIRONMENT}"
        terraform plan -var-file="${TFVARS_FILE}" -out="${PLAN_FILE}"
        echo -e "${GREEN}Plan saved to ${PLAN_FILE}${NC}"
        ;;
    apply)
        echo -e "${YELLOW}Running terraform apply...${NC}"
        PLAN_FILE="${PLANS_DIR}/tfplan_${ENVIRONMENT}"
        if [ -f "${PLAN_FILE}" ]; then
            terraform apply "${PLAN_FILE}"
        else
            terraform apply -var-file="${TFVARS_FILE}" -auto-approve
        fi
        echo -e "${GREEN}Environment ${ENVIRONMENT} applied successfully${NC}"
        ;;
    destroy)
        echo -e "${RED}WARNING: This will destroy the ${ENVIRONMENT} environment${NC}"
        read -p "Are you sure? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            terraform destroy -var-file="${TFVARS_FILE}" -auto-approve
            echo -e "${GREEN}Environment ${ENVIRONMENT} destroyed${NC}"
        else
            echo "Destroy cancelled"
        fi
        ;;
    *)
        echo -e "${RED}Unknown action: $ACTION${NC}"
        echo "Valid actions: plan, apply, destroy"
        exit 1
        ;;
esac

echo -e "${YELLOW}========================================${NC}"
