#!/bin/bash
set -e

# D&D Foundry VTT on Azure - Automated Deployment Script

COLOR_GREEN='\033[0;32m'
COLOR_BLUE='\033[0;34m'
COLOR_YELLOW='\033[1;33m'
COLOR_RED='\033[0;31m'
NC='\033[0m'

echo -e "${COLOR_BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${COLOR_BLUE}D&D Foundry VTT - Azure Deployment${NC}"
echo -e "${COLOR_BLUE}═══════════════════════════════════════════════════${NC}"

# Check prerequisites
echo -e "\n${COLOR_YELLOW}Checking prerequisites...${NC}"

if ! command -v az &> /dev/null; then
    echo -e "${COLOR_RED}✗ Azure CLI not found. Install from: https://aka.ms/InstallAzureCLI${NC}"
    exit 1
fi
echo -e "${COLOR_GREEN}✓ Azure CLI installed${NC}"

if ! command -v terraform &> /dev/null; then
    echo -e "${COLOR_RED}✗ Terraform not found. Install from: https://www.terraform.io/downloads${NC}"
    exit 1
fi
echo -e "${COLOR_GREEN}✓ Terraform installed${NC}"

# Check Azure login
if ! az account show > /dev/null 2>&1; then
    echo -e "${COLOR_YELLOW}Not logged in to Azure. Logging in...${NC}"
    az login
fi
echo -e "${COLOR_GREEN}✓ Azure logged in${NC}"

# Check terraform.tfvars
if [ ! -f terraform.tfvars ]; then
    echo -e "${COLOR_YELLOW}Creating terraform.tfvars from template...${NC}"
    cp terraform.tfvars.example terraform.tfvars
    echo -e "${COLOR_RED}⚠ Please edit terraform.tfvars with your values:${NC}"
    echo "   - foundry_license_key"
    echo "   - database_password"
    echo "   - vm_ssh_public_key"
    echo "   - alert_email"
    exit 1
fi
echo -e "${COLOR_GREEN}✓ terraform.tfvars found${NC}"

# Initialize Terraform
echo -e "\n${COLOR_YELLOW}Initializing Terraform...${NC}"
terraform init
echo -e "${COLOR_GREEN}✓ Terraform initialized${NC}"

# Validate
echo -e "\n${COLOR_YELLOW}Validating Terraform configuration...${NC}"
terraform validate
terraform fmt -recursive ../..
echo -e "${COLOR_GREEN}✓ Configuration valid${NC}"

# Plan
echo -e "\n${COLOR_YELLOW}Planning deployment...${NC}"
terraform plan -out=tfplan
echo -e "${COLOR_GREEN}✓ Plan created${NC}"

# Confirm
read -p "$(echo -e ${COLOR_YELLOW}Proceed with deployment? [y/N]${NC}) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 1
fi

# Deploy
echo -e "\n${COLOR_YELLOW}Applying Terraform configuration...${NC}"
terraform apply tfplan
echo -e "${COLOR_GREEN}✓ Deployment complete${NC}"

# Output results
echo -e "\n${COLOR_BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${COLOR_BLUE}Deployment Summary${NC}"
echo -e "${COLOR_BLUE}═══════════════════════════════════════════════════${NC}"

terraform output

# Save outputs
echo -e "\n${COLOR_YELLOW}Saving deployment outputs...${NC}"
terraform output > deployment_outputs.json
echo -e "${COLOR_GREEN}✓ Outputs saved to deployment_outputs.json${NC}"

# Get public IP
PUBLIC_IP=$(terraform output -raw load_balancer_public_ip)
echo -e "\n${COLOR_YELLOW}Next steps:${NC}"
echo -e "${COLOR_GREEN}1. Access Foundry:${NC} http://${PUBLIC_IP}"
echo -e "${COLOR_GREEN}2. Monitor deployment:${NC} az vmss list-instances -g rg-dnd-foundry-prod --vmss-name vmss-dnd-foundry-prod"
echo -e "${COLOR_GREEN}3. View logs:${NC} az monitor log-analytics workspace show --resource-group rg-dnd-foundry-prod --workspace-name law-dnd-foundry-prod"
echo -e "${COLOR_GREEN}4. Check alerts:${NC} az monitor metrics alert list --resource-group rg-dnd-foundry-prod"

echo -e "\n${COLOR_BLUE}═══════════════════════════════════════════════════${NC}"
