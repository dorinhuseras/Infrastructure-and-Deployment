param vpnVnet object 
param destinationVnet object 


resource vpnNetworkResource 'Microsoft.Network/virtualNetworks@2022-01-01' existing =  {
  name: vpnVnet.name
}

resource destinationNetworkResource 'Microsoft.Network/virtualNetworks@2022-01-01' existing =  {
	scope: resourceGroup(destinationVnet.subscription,destinationVnet.rg)
  name: destinationVnet.name
}

module vpnPeeringModule 'vnetpeering.bicep' = {
  name: 'vnet-peering-module'
	params:{
	  allowForwardedTraffic: true
	  allowGatewayTransit: true
	  allowVirtualNetworkAccess: true
	  destinationNetworkId: destinationNetworkResource.id
	  sourceNetwork: vpnNetworkResource.name
	  useRemoteGateways: false
	  destinationVnetName: destinationNetworkResource.name
	}
}

module vnetPeeringModule 'vnetpeering.bicep' = {
	scope: resourceGroup(destinationVnet.subscription,destinationVnet.rg)
	dependsOn: [vpnPeeringModule]
	name: 'vpn-peering-module'
	params:{
		allowForwardedTraffic: true
		allowGatewayTransit: false
		allowVirtualNetworkAccess: false
		destinationNetworkId: vpnNetworkResource.id
		destinationVnetName: vpnNetworkResource.name
		sourceNetwork: destinationNetworkResource.name
		useRemoteGateways: true
	}
}
