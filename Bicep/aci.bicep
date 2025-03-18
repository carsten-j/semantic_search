param location string
param containerGroupName string
param storageAccountName string
param caddyFileFileShareName string
param caddyDataFileShareName string
param caddyConfigFileShareName string
param qdrantFileShareName string

var publicUrl = toLower('${containerGroupName}.${location}.azurecontainer.io')

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2024-05-01-preview' = {
  name: containerGroupName
  location: location
  properties: {
    sku: 'Standard'
    containers: [
      {
        name: '${containerGroupName}-caddy'
        properties: {
          // https://hub.docker.com/_/caddy
          image: 'docker.io/caddy:latest'
          command: [
            'caddy'
            'reverse-proxy'
            '--from'
            '${publicUrl}'
            '--to'
            'localhost:5000'
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 1
            }
          }
          ports: [
            {
              protocol: 'TCP'
              port: 443
            }
            {
              protocol: 'TCP'
              port: 80
            }
          ]
          volumeMounts: [
            {
              name: caddyFileFileShareName
              mountPath: '/etc/caddy'
              readOnly: false
            }
            {
              name: caddyDataFileShareName
              mountPath: '/data'
              readOnly: false
            }
            {
              name: caddyConfigFileShareName
              mountPath: '/config'
              readOnly: false
            }
          ]
        }
      }
      {
        name: '${containerGroupName}-qdrant'
        properties: {
          image: 'qdrant/qdrant:latest'
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 1
            }
          }
          volumeMounts: [
            {
              name: qdrantFileShareName
              mountPath: '/qdrant/data/'
              readOnly: false
            }
          ]
        }
      }
      {
        name: '${containerGroupName}-api'
        properties: {
          image: 'carstenj/embedding-api:latest'
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 1
            }
          }
          environmentVariables: [
            {
              name: 'PORT'
              value: '5000'
            }
          ]
          ports: [
            {
              port: 5000
              protocol: 'TCP'
            }
          ]
        }
      }
    ]
    osType: 'Linux'
    restartPolicy: 'Never'
    ipAddress: {
      type: 'Public'
      dnsNameLabel: containerGroupName
      ports: [
        {
          protocol: 'TCP'
          port: 443
        }
        {
          protocol: 'TCP'
          port: 80
        }
      ]
    }
    volumes: [
      {
        name: caddyFileFileShareName
        azureFile: {
          shareName: caddyFileFileShareName
          storageAccountName: storageAccount.name
          storageAccountKey: storageAccount.listKeys().keys[0].value
          readOnly: false
        }
      }
      {
        name: caddyDataFileShareName
        azureFile: {
          shareName: caddyDataFileShareName
          storageAccountName: storageAccount.name
          storageAccountKey: storageAccount.listKeys().keys[0].value
          readOnly: false
        }
      }
      {
        name: caddyConfigFileShareName
        azureFile: {
          shareName: caddyConfigFileShareName
          storageAccountName: storageAccount.name
          storageAccountKey: storageAccount.listKeys().keys[0].value
          readOnly: false
        }
      }
      {
        name: qdrantFileShareName
        azureFile: {
          shareName: qdrantFileShareName
          storageAccountName: storageAccount.name
          storageAccountKey: storageAccount.listKeys().keys[0].value
          readOnly: false
        }
      }
    ]
  }
}
