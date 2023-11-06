param sourceNetwork string
param destinationNetworkId string
param allowVirtualNetworkAccess bool 
param allowForwardedTraffic bool 
param allowGatewayTransit bool 
param useRemoteGateways bool 
param destinationVnetName string

resource vnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: '${sourceNetwork}/${destinationVnetName}-peer'
  properties: {
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
    remoteVirtualNetwork: {
      id: destinationNetworkId
    }
  }
}
