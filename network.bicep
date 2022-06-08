targetScope = 'resourceGroup'

param vnetName string

param subnetPrefix string

param subnetName string

var delegationName = 'aciVnetDelegation'

resource vnet 'Microsoft.Network/virtualnetworks@2015-05-01-preview' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' = {
  name: subnetName
  parent: vnet
  properties: {
    addressPrefix: subnetPrefix
    delegations: [
      {
        id: resourceId('Microsoft.Network', vnetName, 'subnets', subnetName, 'delegations', delegationName)
        name: delegationName
        properties: {
          serviceName: 'Microsoft.ContainerInstance/containerGroups'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
      }
    ]
  }
  
}

output subnetId string = subnet.id
