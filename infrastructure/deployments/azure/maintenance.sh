#!/bin/bash

# D&D Foundry VTT on Azure - Maintenance Script

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

RESOURCE_GROUP="rg-dnd-foundry-prod"
VMSS_NAME="vmss-dnd-foundry-prod"
PROJECT_NAME="dnd-foundry"

echo -e "${YELLOW}D&D Foundry VTT - Maintenance Tasks${NC}"
echo "======================================"
echo "1. Check VM Scale Set Status"
echo "2. View Recent Logs"
echo "3. Check Database Status"
echo "4. View Storage Usage"
echo "5. Check Alert Status"
echo "6. Scale Instances"
echo "7. Restart VMs"
echo "8. Database Backup"
echo "9. View Performance Metrics"
echo "10. Security Audit"
echo "======================================"
read -p "Select option (1-10): " option

case $option in
  1)
    echo -e "${GREEN}VM Scale Set Status:${NC}"
    az vmss show -g $RESOURCE_GROUP --name $VMSS_NAME --query "properties | {skuCapacity: sku.capacity, skuName: sku.name, vmSize}"
    az vmss list-instances -g $RESOURCE_GROUP --vmss-name $VMSS_NAME --query "[*].[instanceId, provisioningState, powerState]"
    ;;
  2)
    echo -e "${GREEN}Recent Foundry Logs:${NC}"
    az vmss run-command invoke \
      --resource-group $RESOURCE_GROUP \
      --name $VMSS_NAME \
      --instance-ids 0 \
      --command-id RunShellScript \
      --scripts "docker logs foundry --tail 50"
    ;;
  3)
    echo -e "${GREEN}Database Status:${NC}"
    az mysql flexible-server show -g $RESOURCE_GROUP --name mysql-${PROJECT_NAME}-prod \
      --query "{status: state, version: version, sku: sku.name, storage: storage.storageSizeGB}"
    ;;
  4)
    echo -e "${GREEN}Storage Account Usage:${NC}"
    STORAGE_ACCOUNT=$(az storage account list -g $RESOURCE_GROUP --query "[0].name" -o tsv)
    az storage container list --account-name $STORAGE_ACCOUNT --query "[*].[name, properties.lease.state]" -o table
    ;;
  5)
    echo -e "${GREEN}Active Alerts:${NC}"
    az monitor metrics alert list -g $RESOURCE_GROUP --query "[*].[name, enabled, severity]" -o table
    ;;
  6)
    read -p "Enter number of instances (2-10): " instances
    az vmss scale -g $RESOURCE_GROUP --name $VMSS_NAME --new-capacity $instances
    echo -e "${GREEN}Scaled to $instances instances${NC}"
    ;;
  7)
    read -p "Restart all VMs? (y/N): " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      az vmss restart -g $RESOURCE_GROUP --name $VMSS_NAME
      echo -e "${GREEN}VMs restarting...${NC}"
    fi
    ;;
  8)
    echo -e "${GREEN}Creating database backup...${NC}"
    BACKUP_NAME="backup-$(date +%Y%m%d-%H%M%S)"
    az mysql flexible-server backup create \
      --resource-group $RESOURCE_GROUP \
      --server-name mysql-${PROJECT_NAME}-prod \
      --backup-name $BACKUP_NAME
    echo -e "${GREEN}Backup created: $BACKUP_NAME${NC}"
    ;;
  9)
    echo -e "${GREEN}Performance Metrics (Last 1 hour):${NC}"
    VMSS_ID="/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Compute/virtualMachineScaleSets/$VMSS_NAME"
    az monitor metrics list --resource $VMSS_ID --metric "Percentage CPU" "Available Memory Bytes" --interval PT5M --start-time "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ)" --aggregation Average
    ;;
  10)
    echo -e "${GREEN}Security Audit:${NC}"
    echo "NSG Rules:"
    az network nsg rule list --resource-group $RESOURCE_GROUP --nsg-name "nsg-snet-app" --query "[*].[name, access, protocol, sourcePortRange, destinationPortRange]" -o table
    echo -e "\nRole Assignments:"
    az role assignment list --resource-group $RESOURCE_GROUP --query "[*].[principalName, roleDefinitionName]" -o table
    ;;
  *)
    echo "Invalid option"
    ;;
esac
