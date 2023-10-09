param projectName string
param virtualNetwrokId string
param privateDnsName string

resource privateDnsResource 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsName
}

resource resourcePrivateDnsNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
 name: '${projectName}-dns-link'
 location: 'global'
 parent: privateDnsResource
 properties: {
  registrationEnabled: false
  virtualNetwork: {
    id: virtualNetwrokId
  }
 }
}