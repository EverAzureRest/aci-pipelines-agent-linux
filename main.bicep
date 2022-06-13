targetScope = 'resourceGroup'

@description('The Name of the ACI Container Group')
param containerGroupName string = 'adoshagent'

@description('Number of Self-Hosted Agent Containers to create')
param numberOfInstances int = 2

@description('Name of the Image to be pulled or created in the Registry')
param Image string = 'adoshagent'

@description('Image Version Tag')
param imageVersion string = 'latest'

@description('URL to the DevOps Org')
param ADO_Account string 

@description('Pool name for the Self-Hosted Agents in ADO')
param ADO_Pool string = 'SelfHostedACI'

@description('KeyVault Name')
param keyVaultName string 

@description('KeyVault Resource Group')
param keyVaultRG string 

@description('ADO PAT Secret Name in KeyVault')
param secretName string 

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

@description('current repo branch if building container through source control in this template')
param sourceBranch string = 'master'

@description('URI to the code repository with the Dockerfile - define or change if forked')
param dockerSourceRepo string = 'https://github.com/everazurerest/aci-pipelines-agent-linux.git'

module network 'network.bicep' = {
  name: 'NetworkDeployment'
  scope: resourceGroup(vnetRGName)
  params: {
    vnetName: vnetName
    subnetName: subnetName
    subnetPrefix: subnetPrefix
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  name: keyVaultName
  scope: resourceGroup(keyVaultRG)
}

module registry 'registry.bicep' =  {
  name: 'RegistryDeployment'
  scope: resourceGroup(containerRegistryRG)
  params: {
    containerRegistryName: containerRegistryName
    registrySku: 'Basic'
    location: location
    dockerSourceRepo:dockerSourceRepo
    branch: sourceBranch
    image: Image
    imageVersion: imageVersion
  }
}

module containerGroupDeployment 'containers.bicep' = [for i in range(0, numberOfInstances): {
  name: 'containerDeployment-${i}'
  scope: resourceGroup()
  params: {
    containerGroupName: '${containerGroupName}${i}'
    location: location
    image: registry.outputs.image
    ADO_Account: ADO_Account
    AZP_Token: keyVault.getSecret(secretName)
    ADO_Pool: ADO_Pool
    subnetId: network.outputs.subnetId
    agentCPU: agentCPU
    agentMem: agentMem
    containerRegistryName: containerRegistryName
    containerRegistryRG: containerRegistryRG
  }
}]



