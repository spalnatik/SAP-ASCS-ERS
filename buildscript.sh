#!/bin/bash

# Set variables
ResourceGroup="sles-ha-rg"
Location="EastUS"
DiskSizeInGB=4
DiskName="SBD-disk1"
ShareNodes=2
SkuName="Premium_LRS"




az disk create --resource-group sles-ha-rg --name nw1-cl1-0-osdisk --source /subscriptions/152eb83a-1242-4c87-9b30-668a34d57eae/resourceGroups/sles-ha-rg-lab/providers/Microsoft.Compute/snapshots/nw1-cl1-0-ss --query id --output tsv
az disk create --resource-group sles-ha-rg --name nw1-cl1-1-OSdisk --source /subscriptions/152eb83a-1242-4c87-9b30-668a34d57eae/resourceGroups/sles-ha-rg-lab/providers/Microsoft.Compute/snapshots/nw1-cl1-1-Snapshot --query id --output tsv


az vm create --name nw1-cl-0 --resource-group sles-ha-rg --attach-os-disk nw1-cl1-0-osdisk --os-type linux --location EastUS --vnet-name havnet --subnet hasubnet --private-ip-address 10.0.0.8 --public-ip-sku Standard

az vm create --name nw1-cl-1 --resource-group sles-ha-rg --attach-os-disk nw1-cl1-1-OSdisk --os-type linux --location EastUS --vnet-name havnet --subnet hasubnet --private-ip-address 10.0.0.9 --public-ip-sku Standard



az network lb create --resource-group sles-ha-rg --name SAP-LB  --location EastUS --backend-pool-name sap-bp --frontend-ip-name nw1-ascs --private-ip-address "10.0.0.10" --sku "Standard" --vnet-name havnet --subnet hasubnet 

az network lb frontend-ip create -g sles-ha-rg --lb-name SAP-LB -n nw1-ERS --vnet-name havnet --subnet hasubnet --private-ip-address "10.0.0.11"

az network lb probe create -g sles-ha-rg --lb-name SAP-LB  -n ASCS-HP --protocol tcp --port 62100
az network lb probe create -g sles-ha-rg --lb-name SAP-LB  -n ERS-HP --protocol tcp --port 62102


nic1name1=`az vm show -g sles-ha-rg -n nw1-cl-0  --query networkProfile.networkInterfaces[].id -o tsv | cut -d / -f 9`


az network nic ip-config address-pool add --address-pool sap-bp  --ip-config-name ipconfignw1-cl-0 --nic-name $nic1name1 -g sles-ha-rg --lb-name SAP-LB


nic1name2=`az vm show -g sles-ha-rg -n nw1-cl-1  --query networkProfile.networkInterfaces[].id -o tsv | cut -d / -f 9`


az network nic ip-config address-pool add --address-pool sap-bp  --ip-config-name ipconfignw1-cl-1 --nic-name $nic1name2 -g sles-ha-rg --lb-name SAP-LB


az network lb rule create -g sles-ha-rg  --lb-name SAP-LB  -n ASCS-lbrule --protocol All --frontend-ip-name nw1-ascs --frontend-port 0 --backend-pool-name sap-bp --backend-port 0 --probe-name ASCS-HP  --floating-ip true --idle-timeout 30

az network lb rule create -g sles-ha-rg  --lb-name SAP-LB  -n ERS-lbrule --protocol All --frontend-ip-name nw1-ERS --frontend-port 0 --backend-pool-name sap-bp --backend-port 0 --probe-name ERS-HP  --floating-ip true --idle-timeout 30



az vm extension set \
    --resource-group sles-ha-rg \
    --vm-name nfs-0 \
    --name customScript \
    --publisher Microsoft.Azure.Extensions \
    --protected-settings '{"fileUris": ["https://raw.githubusercontent.com/spalnatik/SAP-ASCS-ERS/main/data.sh"],"commandToExecute": "./data.sh"}' 
	

az vm extension set \
    --resource-group sles-ha-rg \
    --vm-name nw1-cl-0 \
    --name customScript \
    --publisher Microsoft.Azure.Extensions \
    --protected-settings '{"fileUris": ["https://raw.githubusercontent.com/spalnatik/SAP-ASCS-ERS/main/softlinks.sh"],"commandToExecute": "./softlinks.sh"}' 


# Create managed disk
az disk create --resource-group $ResourceGroup --name $DiskName --location $Location --sku $SkuName --size-gb $DiskSizeInGB --max-shares $ShareNodes --query id --output tsv

# Attach disk to VM1
az vm disk attach --resource-group sles-ha-rg --vm nw1-cl-0 --name SBD-DISK1 --lun 0

# Attach disk to VM2
az vm disk attach --resource-group sles-ha-rg --vm nw1-cl-1 --name SBD-DISK1 --lun 0


az vm extension set \
    --resource-group sles-ha-rg \
    --vm-name nw1-cl-0 \
    --name customScript \
    --publisher Microsoft.Azure.Extensions \
    --protected-settings '{"fileUris": ["https://raw.githubusercontent.com/spalnatik/SAP-ASCS-ERS/main/shareddisk.sh"],"commandToExecute": "./shareddisk.sh"}' 

az vm extension set \
    --resource-group sles-ha-rg \
    --vm-name nw1-cl-1 \
    --name customScript \
    --publisher Microsoft.Azure.Extensions \
    --protected-settings '{"fileUris": ["https://raw.githubusercontent.com/spalnatik/SAP-ASCS-ERS/main/shareddisk2.sh"],"commandToExecute": "./shareddisk2.sh"}' 
