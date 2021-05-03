# Overview

This script will do the following:

1.  Create a Resource Group
2.  Setup a Storage Account for use with Batch
3.  Create a Virtual Network (vnet) and subnet 
4.  Create a Key Vault and configure it for use with Azure Batch
5.  Create a new Azure Batch account using Key Vault and Storage Account
6.  Login to the Batch account using Azure CLI
7.  Create a Batch application package for EnergyPlus v9.4.0
