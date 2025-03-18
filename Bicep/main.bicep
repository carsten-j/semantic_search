@description('The location to deploy the resources to.')
param location string = 'swedencentral'

@description('The name of the container group to create.')
param containerGroupName string

@description('The name of the storage account to create.')
param storageAccountName string

@description('Create a storage account and file share to persist data for the Caddy container.')
module storageAccount './storage-account.bicep' = {
  name: toLower('deploy-storage-account-module-${storageAccountName}')
  params: {
    location: location
    storageAccountName: storageAccountName
    containerGroupName: containerGroupName
  }
}

@description('Create an ACI container group to run the Hello World and Caddy containers.')
module aci './aci.bicep' = {
  name: toLower('deploy-aci-module-${containerGroupName}')
  params: {
    location: location
    storageAccountName: storageAccountName
    containerGroupName: containerGroupName
    caddyDataFileShareName: storageAccount.outputs.caddyDataFileShareName
    caddyFileFileShareName: storageAccount.outputs.caddyFileFileShareName
    caddyConfigFileShareName: storageAccount.outputs.caddyConfigFileShareName
    qdrantFileShareName: storageAccount.outputs.qdrantFileShareName
  }
}
