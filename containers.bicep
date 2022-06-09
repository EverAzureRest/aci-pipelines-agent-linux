targetScope = 'resourceGroup'

param containerGroupName string
param location string
param image string
param ADO_Account string
@secure()
param AZP_Token string
param ADO_Pool string
param subnetId string
param agentCPU int
param agentMem int
param containerRegistryName string
param containerRegistryRG string

resource registryServer 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: containerRegistryName
  scope: resourceGroup(containerRegistryRG)
}

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-10-01' = {
  name: containerGroupName
  location: location
  properties: {
    containers: [
      {
        name: containerGroupName
        properties: {
          image: image
          environmentVariables: [
            {
              name: 'AZP_URL'
              value: ADO_Account
            }
            {
              name: 'AZP_TOKEN'
              value: AZP_Token
            }
            {
              name: 'AZP_POOL'
              value: ADO_Pool
            }
          ]
          resources: {
            requests: {
              cpu: agentCPU
              memoryInGB: agentMem
            }
          }
        }
      }
    ]
    imageRegistryCredentials: [
      {
      server: registryServer.properties.loginServer
      password: registryServer.listCredentials().passwords[0].value
      username: registryServer.name
      }
    ]
    osType: 'Linux'
    subnetIds: [
      {
        id: subnetId
      }
    ]
  }
}

