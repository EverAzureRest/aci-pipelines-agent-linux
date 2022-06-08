targetScope = 'resourceGroup'

@description('The Name of the ACI Container Group')
param containerGroupName string = 'adoSHAgent'

@description('Number of Self-Hosted Agent Containers to create')
param numberOfInstances int = 2

@description('Full path to the container image')
param Image string

@description('Image Version')
param imageVersion string = 'latest'

@description('URL to the DevOps Org')
param ADO_Account string

@description('KeyVault Reference to the ADO Token')
param ADO_Token string

@description('Pool name for the Self-Hosted Agents in ADO')
param ADO_Pool string = 'Default'

@description('Name of the VNET to connect the agent containers')
param vnetName string

@description('Name of the Resource Group containing the VNET')
param vnetRGName string

@description('Name of the subnet in the VNET to connect the agent containers')
param subnetName string

@description('Subnet CIDR prefix for the Container Instance subnet')
param subnetPrefix string

@description('Number of cores assigned to each container instance')
param agentCPU int = 1

@description('The amount of Memory in GB for each container instance')
param agentMem int = 3

@description('Name of the Container Registry')
param containerRegistryName string

@description('Resource Group of the Container Registry')
param containerRegistryRG string

@description('Deployment Region')
param location string = resourceGroup().location

@description('current repo branch if building container through source control')
param sourceBranch string = 'testing'

@description('URI to the code repository with the Dockerfile - define or change if forked')
param dockerSourceRepo string = 'https://github.com/everazurerest/aci-pipelines-agent-linux'

@description('Role Definition Id for the ACR Pull role')
param roleDefinitionId string = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

module network 'network.bicep' = {
  name: 'Network Deployment'
  scope: resourceGroup(vnetRGName)
  params: {
    vnetName: vnetName
    subnetName: subnetName
    subnetPrefix: subnetPrefix
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: containerRegistryName
  scope: resourceGroup(containerRegistryRG)
}

module registry 'registry.bicep' = if (!empty(containerRegistry.id)) {
  name: 'Registry Deployment'
  scope: resourceGroup(containerRegistryRG)
  params: {
    containerRegistryName: containerRegistryName
    registrySku: 'Basic'
    location: location
    dockerSourceRepo:dockerSourceRepo
    branch: sourceBranch
  }
}
/*
resource networkProfile 'Microsoft.Network/networkProfiles@2021-08-01' = {
  name: 'adoAgentNetworkProfile'
  location: location
  properties: {
    containerNetworkInterfaceConfigurations: [
      {
        name: 'eth0'
        properties: {
          ipConfigurations: [
            {
              name: 'ipConfig1'
              properties: {
                subnet: {
                  id: network.outputs.subnetId
                }
              }
            }
          ]
        }
      }
    ]
  }
}
*/

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-10-01' = [for i in range(0, numberOfInstances): {
  name: '${containerGroupName}-${i}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    containers: [
      {
        name: '${containerGroupName}-${i}'
        properties: {
          image: ((!empty(registry.outputs.image)) ? '${containerRegistry.properties.loginServer}/${Image}':imageVersion)
          environmentVariables: [
            {
              name: 'AZP_URL'
              value: ADO_Account
            }
            {
              name: 'AZP_TOKEN'
              value: ADO_Token
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
    osType: 'Linux'
    subnetIds: [
      {
        id: network.outputs.subnetId
      }
    ]
  }
}]

resource containerRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = [for i in range (0, numberOfInstances): {
  name: '${guid(resourceGroup().id, roleDefinitionId)}-${i}'
  scope: resourceGroup()
  properties: {
    principalId: containerGroup[i].identity.principalId
    roleDefinitionId: roleDefinitionId
  }
}]
