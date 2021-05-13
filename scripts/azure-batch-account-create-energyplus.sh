#!/bin/bash

set -x

#az login --use-device-code 

# UPDATE these variables
app=energyplus
app_version=9.4.0
local_app_path='~/Downloads/EnergyPlus-9.4.0-998c4b761e-Windows-x86_64.zip'  # path on local machine for EP zip file
org=azdemo              # organization name/acronym, lowercase no special characters    
region=southcentralus   # Azure Region to use


# Batch variables
# Note: batch_name and storage_account_name need to be unique and are limited to 3-24 lowercase alphanumeric characters
# Note: storage name can only have lowercase alphanumeric characters...no special characters
batch_rg=${org}-${app}-batch-rg
sub_id=$(az account show --query id --output tsv) # if executing this from subscription, else hard code sub_idd
vnet_2_octets="10.25"
batch_name=${org}${app}batch


# Check for storage account unique name (must be GLOBALLY unique)
storage_account_name=${org}${app}sa
az storage account check-name --name ${storage_account_name} > sa-name
i=0
while grep -q "false" sa-name; do
    storage_account_name=${org}${app}${i}sa
    az storage account check-name --name ${storage_account_name} > sa-name
    ((i++))
done


# Set az to the correct subscription
az account set -s ${sub_id}


# Create batch rg
az group create -l ${region} -n ${batch_rg}


#
# Setup storage account for batch
az storage account create \
  -n ${storage_account_name} \
  -g ${batch_rg} \
  -l ${region} \
  --sku Standard_LRS \
  --encryption-services blob


#
# Setup network
#
az network vnet create -g ${batch_rg} -n eplusvnet --address-prefix ${vnet_2_octets}.0.0/16 \
  --subnet-name default --subnet-prefix ${vnet_2_octets}.0.0/24


#
# Create Azure Key Vault
#
az keyvault create \
  --location ${region} \
  --name ${batch_name}kv \
  --resource-group ${batch_rg} \
  --enabled-for-deployment true \
  --enabled-for-template-deployment true


# Add batch service to the keyvault policies
#
az keyvault set-policy \
  --name ${batch_name}kv \
  --resource-group ${batch_rg} \
  --secret-permissions get list set recover delete \
  --spn MicrosoftAzureBatch


#
# Create batch account
#
az batch account create \
  -l ${region} \
  -n ${batch_name} \
  -g ${batch_rg} \
  --keyvault ${batch_name}kv \
  --storage-account ${storage_account_name}


# Login to batch account
#
az batch account login \
--name ${batch_name} \
--resource-group ${batch_rg} 


# Create the EnergyPlus application for Azure Batch
# SOURCE: https://github.com/NREL/EnergyPlus/releases/download/v9.4.0/EnergyPlus-9.4.0-998c4b761e-Windows-x86_64.zip
az batch application package create --application-name ${app} -g ${batch_rg} -n ${batch_name} --package-file ${local_app_path} --version-name ${app_version}
