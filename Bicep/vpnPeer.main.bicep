param location string = resourceGroup().location

@allowed(['Dev','Prod'])
@description('Environment name, should be set as a pipeline variable. Default value is Dev')
param environmentName string = 'Dev'

@description('Project name, should be set as a pipeline variable')
param projectName string

@description('VNet definition object')
param vnet object

@description('Resource tags object that sgould link resources ot one project')
param resourceTags object = {
	RequirdFor: 'AzureVPN'
}

param vnetPeers array
 
param firstDeployment bool = false

module virtualNetworkModule 'modules/virtualnetwork.bicep' = {
	name: '${projectName}Vnet-module'
	params: {
		location: location
		resourceTags: resourceTags
		subnets: vnet.subnets
		virtualNetworkName: '${environmentName}${projectName}-vnet'
		vnetAddressSpaces: vnet.vnetAddressSpaces
	}
}


//Prepare Vnets resources for refrence
resource vpnGatewaySubnetResource 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' existing = {
  name: '${virtualNetworkModule.outputs.vnetResourceSimbolicName}/GatewaySubnet'
}


resource dnsResolverSubnetResource 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' existing = {
  name: '${virtualNetworkModule.outputs.vnetResourceSimbolicName}/DnsResolver'
}


module vpnGatewayModule 'modules/vpngateway.bicep' = if (firstDeployment){
	name: '${projectName}Ag-module'
	params: {
		location: location
		projectName: '${environmentName}${projectName}'
		resourceTags: resourceTags
		subnetId: vpnGatewaySubnetResource.id
		tenantId: subscription().tenantId
	}
}

@description('A private DNS resolver is required to push dns names trough the VPN connection')
resource privateDnsResoiverResource 'Microsoft.Network/dnsResolvers@2022-07-01' = {
  name: '${projectName}Dns-resolver'
  location: location
  tags: resourceTags
  properties: {
    virtualNetwork: {
      id: virtualNetworkModule.outputs.vnetResourceId
    }
  }
}

resource inboundEndpointResource 'Microsoft.Network/dnsResolvers/inboundEndpoints@2022-07-01' = {
	name: '${projectName}Inbound'
	location: location
	parent: privateDnsResoiverResource
	tags: resourceTags
	properties: {
		ipConfigurations: [{
			privateIpAllocationMethod: 'Dynamic'
			subnet: {
				id: dnsResolverSubnetResource.id
			}
		}]
	}
}

var dhcpOptions  = {
	dhcpOptions: { 
		dnsServers: [
			inboundEndpointResource.properties.ipConfigurations[0].privateIpAddress
		]
	}
}

resource vnetResource 'Microsoft.Network/virtualNetworks@2022-01-01' = {
	name: '${environmentName}${projectName}-vnet'
	location: location
	dependsOn: [virtualNetworkModule]
	tags: resourceTags
	properties: union(virtualNetworkModule.outputs.vnetProperty, dhcpOptions)
}


//create private DNS for each service type Blob, Storage  Vault and SQL 
module privateStorageTableDnsModule 'modules/privatedns.bicep' = {
	name: 'privateStorageTableDns-module'
	params: {
		dnsConfig: 'StorageTable'
		resourceName: virtualNetworkModule.outputs.vnetResourceSimbolicName
		resourceTags: resourceTags
		virtualNetwrokId: virtualNetworkModule.outputs.vnetResourceId
	}
}


module privateStorageBlobDnsModule 'modules/privatedns.bicep' = {
	name: 'privateStorageBlobDns-module'
	params: {
		dnsConfig: 'StorageBlob'
		resourceName: virtualNetworkModule.outputs.vnetResourceSimbolicName
		resourceTags: resourceTags
		virtualNetwrokId: virtualNetworkModule.outputs.vnetResourceId
	}
}

module privateSqlServerDnsModule 'modules/privatedns.bicep' = {
	name: 'privateSqlServerDns-module'
	params: {
		dnsConfig: 'SqlServer'
		resourceName: virtualNetworkModule.outputs.vnetResourceSimbolicName
		resourceTags: resourceTags
		virtualNetwrokId: virtualNetworkModule.outputs.vnetResourceId
	}
}

module privateKeyVaultDnsModule 'modules/privatedns.bicep' = {
	name: 'privateKeyVaultDns-module'
	params: {
		dnsConfig: 'KeyVault'
		resourceName: virtualNetworkModule.outputs.vnetResourceSimbolicName
		resourceTags: resourceTags
		virtualNetwrokId: virtualNetworkModule.outputs.vnetResourceId
	}
}

	module privateCosmosTableDnsModule 'modules/privatedns.bicep' = {
	name: 'privateCosmosTableDns-module'
	params: {
		dnsConfig: 'CosmosTable'
		resourceName: virtualNetworkModule.outputs.vnetResourceSimbolicName
		resourceTags: resourceTags
		virtualNetwrokId: virtualNetworkModule.outputs.vnetResourceId
	}
}

module privateWebSiteDnsModule 'modules/privatedns.bicep' = {
	name: 'privateWebSiteDns-module'
	params: {
		dnsConfig: 'WebSite'
		resourceName: virtualNetworkModule.outputs.vnetResourceSimbolicName
		resourceTags: resourceTags
		virtualNetwrokId: virtualNetworkModule.outputs.vnetResourceId
	}
}

module privateRedisCacheDnsModule 'modules/privatedns.bicep' = {
	name: 'privateRedisCacheDns-module'
	params: {
		dnsConfig: 'RedisCache'
		resourceName: virtualNetworkModule.outputs.vnetResourceSimbolicName
		resourceTags: resourceTags
		virtualNetwrokId: virtualNetworkModule.outputs.vnetResourceId
	}
}

@batchSize(1)
module vpnPeeringModule 'modules/vpnpeering.bicep' = [for resource in vnetPeers: {
  name: '${resource.name}-peer-mdule'
	dependsOn: [virtualNetworkModule]
  params: {
    destinationVnet: resource
    vpnVnet: {
      name: virtualNetworkModule.outputs.name
    }
  }
}]
