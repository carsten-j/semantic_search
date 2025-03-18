param location string
param containerGroupName string
param storageAccountName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    dnsEndpointType: 'Standard'
    allowedCopyScope: 'AAD'
    allowCrossTenantReplication: false
    isSftpEnabled: false
    isNfsV3Enabled: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    largeFileSharesState: 'Enabled'
    isHnsEnabled: true
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
    encryption: {
      requireInfrastructureEncryption: true
      services: {
        file: {
          enabled: true
          keyType: 'Account'
        }
      }
      keySource: 'Microsoft.Storage'
    }
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    protocolSettings: {
      smb: {
        versions: 'SMB3.0'
      }
    }
    shareDeleteRetentionPolicy: {
      enabled: false
      allowPermanentDelete: true
    }
  }
}

resource caddyFileFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01' = {
  parent: fileServices
  name: '${containerGroupName}-caddyfile'
  properties: {
    shareQuota: 1
    accessTier: 'TransactionOptimized'
    enabledProtocols: 'SMB'
  }
}

resource caddyDataFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01' = {
  parent: fileServices
  name: '${containerGroupName}-caddydata'
  properties: {
    shareQuota: 1
    accessTier: 'TransactionOptimized'
    enabledProtocols: 'SMB'
  }
}

resource caddyConfigFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01' = {
  parent: fileServices
  name: '${containerGroupName}-caddyconfig'
  properties: {
    shareQuota: 1
    accessTier: 'TransactionOptimized'
    enabledProtocols: 'SMB'
  }
}

resource qdrantFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01' = {
  parent: fileServices
  name: '${containerGroupName}-qdrant'
  properties: {
    shareQuota: 1
    accessTier: 'TransactionOptimized'
    enabledProtocols: 'SMB'
  }
}

output caddyFileFileShareName string = caddyFileFileShare.name
output caddyDataFileShareName string = caddyDataFileShare.name
output caddyConfigFileShareName string = caddyConfigFileShare.name
output qdrantFileShareName string = qdrantFileShare.name
