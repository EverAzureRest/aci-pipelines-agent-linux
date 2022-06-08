targetScope = 'resourceGroup'

param containerRegistryName string

param registrySku string = 'Basic'

param location string = resourceGroup().location

param dockerSourceRepo string

param branch string

resource registry 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: containerRegistryName
  location: location
  sku: {
    name: registrySku
  }
}

resource buildTask 'Microsoft.ContainerRegistry/registries/buildTasks@2018-02-01-preview' = {
  name: 'BuildTask'
  parent: registry
  location: location
  properties: {
    alias: 'buildADOAgent'
    platform: {
      cpu: 1
      osType: 'Linux'
    }
    sourceRepository: {
      repositoryUrl: dockerSourceRepo
      sourceControlType: 'Github'
    }
  }
}

resource buildStep 'Microsoft.ContainerRegistry/registries/buildTasks/steps@2018-02-01-preview' = {
  name: 'ADOAgentBuild'
  parent: buildTask
  properties: {
    type: 'Docker'
    branch: branch
    dockerFilePath: '/docker'
    imageNames: [
      '${registry.properties.loginServer}/adoshagent'
    ]
    isPushEnabled: true
  }
}

output image string = buildStep.properties.imageNames[0]
