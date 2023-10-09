param location string 

param virtualNetworkName string

param vnetAddressSpaces array 

@description('The name and IP address range for each subnet in the virtual networks.')
param subnets array

param resourceTags object

var subnetProperties = [for subnet in subnets: {
  name: subnet.name
  properties: {
    addressPrefix: subnet.ipAddressRange
    delegations: subnet.delegations
  }
}]

resource virtualNetworkResource 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: virtualNetworkName
  location: location
  tags: resourceTags
  properties: {
    addressSpace: {
      addressPrefixes: vnetAddressSpaces
    }
    
    subnets: subnetProperties
    enableDdosProtection: false
  }
}

output vnetResourceId string = virtualNetworkResource.id
output vnetResourceSimbolicName string = virtualNetworkResource.name
output vnetProperty object = virtualNetworkResource.properties
output vnetTags object = virtualNetworkResource.tags
output name string = virtualNetworkResource.name
