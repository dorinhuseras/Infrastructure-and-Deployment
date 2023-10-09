param location string = resourceGroup().location

@description('VNet definition object')
param vnet object

param resourceTags object

param storageAccounts array = []

param sqlServers array = []

param cosmosServers array = []

param redisCaches array = []

param WebSites array = []

param keyvaults array = []

resource virtualNetworkResource 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: vnet.name
}

//Prepare network ids for each type of resource section
resource storageSubnetResource 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' existing = {
 parent: virtualNetworkResource
 name: 'storage-subnet'
}

resource databaseServerSubnetResource 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' existing = {
 parent: virtualNetworkResource
 name: 'sql-servers-subnet'
}

resource keyVaultSubnetResource 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' existing = {
 parent: virtualNetworkResource
 name: 'keyvault-subnet'
}

resource redisCacheSubnetResource 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' existing = {
 parent: virtualNetworkResource
 name: 'redis-cache-subnet'
}

resource servicesSubnetResource 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' existing = {
	parent: virtualNetworkResource
	name: 'services-subnet'
 }
//End of Prepare network ids for each type of resource section


//Private DNS creation section
module privateStorageTableDnsModule '../modules/privatedns.bicep' = {
	name: 'privateStorageTableDns-module'
	params: {
		dnsConfig: 'StorageTable'
		resourceName: virtualNetworkResource.name
		resourceTags: resourceTags
		virtualNetwrokId: virtualNetworkResource.id
	}
}

module privateStorageBlobDnsModule '../modules/privatedns.bicep' = {
	name: 'privateStorageBlobDns-module'
	params: {
		dnsConfig: 'StorageBlob'
		resourceName:  virtualNetworkResource.name
		resourceTags: resourceTags
		virtualNetwrokId: virtualNetworkResource.id
	}
}

module privateCosmosTableDnsModule '../modules/privatedns.bicep' = if (length(cosmosServers) > 0) {
	name: 'privateCosmosTableDns-module'
	params: {
		dnsConfig: 'CosmosTable'
		resourceName: virtualNetworkResource.name
		resourceTags: resourceTags
		virtualNetwrokId: virtualNetworkResource.id
	}
}

module privateSqlServerDnsModule '../modules/privatedns.bicep' = {
	name: 'privateSqlServerDns-module'
	params: {
		dnsConfig: 'SqlServer'
		resourceName: virtualNetworkResource.name
		resourceTags: resourceTags
		virtualNetwrokId: virtualNetworkResource.id
	}
}

module privateKeyVaultDnsModule '../modules/privatedns.bicep' = {
	name: 'privateKeyVaultDns-module'
	params: {
		dnsConfig: 'KeyVault'
		resourceName: virtualNetworkResource.name
		resourceTags: resourceTags
		virtualNetwrokId: virtualNetworkResource.id
	}
}

module privateRedisCacheDnsModule '../modules/privatedns.bicep' = if (length(redisCaches) > 0){
	name: 'privateRedisCacheDns-module'
	params: {
		dnsConfig: 'RedisCache'
		resourceName: virtualNetworkResource.name
		resourceTags: resourceTags
		virtualNetwrokId: virtualNetworkResource.id
	}
}

module privateWebSiteDnsModule '../modules/privatedns.bicep' = {
	name: 'privateWebSiteDns-module'
	params: {
		dnsConfig: 'WebSite'
		resourceName: virtualNetworkResource.name
		resourceTags: resourceTags
		virtualNetwrokId: virtualNetworkResource.id
	}
}
//End of Private DNS creation section


//Private endpoints creation section 
module peExistingTableStorageModule '../modules/peExistingStorage.bicep' = [for resource in storageAccounts: {
	name: '${resource.name}-Table-Pe-Module'
	params: {
		dnsConfig: 'StorageTable'
		resourceName: resource.name 
		location: location
		privateDnsResourceId: privateStorageTableDnsModule.outputs.privateDnsResourceId
		resourceTags: resourceTags
		subnetResourceId: storageSubnetResource.id
		resourceRg: resource.rg
		subscriptionId: resource.subId
	}
}]

module peExistingBlobStorageModule '../modules/peExistingStorage.bicep' = [for resource in storageAccounts: {
	name: '${resource.name}-Blob-Pe-Module'
	params: {
		dnsConfig: 'StorageBlob'
		resourceName: resource.name
		location: location
		privateDnsResourceId: privateStorageBlobDnsModule.outputs.privateDnsResourceId
		resourceTags: resourceTags
		subnetResourceId: storageSubnetResource.id
		resourceRg: resource.rg
		subscriptionId: resource.subId
	}
}]

module peExistingSqlModule '../modules/peExistingSqlServer.bicep' = [for resource in sqlServers: {
	name: '${resource.name}-SqlServer-Pe-Module'
	params: {
		dnsConfig: 'SqlServer'
		resourceName: resource.name
		location: location
		privateDnsResourceId: privateSqlServerDnsModule.outputs.privateDnsResourceId
		resourceTags: resourceTags
		subnetResourceId: databaseServerSubnetResource.id
		resourceRg: resource.rg
		subscriptionId: resource.subId
	}
}]


module peExistingKeyVaultModule '../modules/peExistingKeyVault.bicep' = [for resource in keyvaults: {
	name: '${resource.name}-KeyVault-pe-module'
	params: {
		dnsConfig: 'KeyVault'
		resourceName: resource.name
		location: location
		privateDnsResourceId: privateKeyVaultDnsModule.outputs.privateDnsResourceId
		resourceTags: resourceTags
		subnetResourceId: keyVaultSubnetResource.id
		resourceRg: resource.rg
		subscriptionId: resource.subId
	}
}]


module peExistingCosmosModule '../modules/peExistingCosmos.bicep' = [for resource in cosmosServers: {
	name: '${resource.name}-Cosmos-pe-module'
	params: {
		dnsConfig: 'CosmosTable'
		resourceName: resource.name
		location: location
		privateDnsResourceId: privateCosmosTableDnsModule.outputs.privateDnsResourceId
		resourceTags: resourceTags
		subnetResourceId: storageSubnetResource.id
		resourceRg: resource.rg
		subscriptionId: resource.subId
	}
}]


module peExistingRedisCacheModule '../modules/peExistingRedisCache.bicep' = [for resource in redisCaches: {
	name: '${resource.name}-Redis-pe-module'
	params: {
		dnsConfig: 'RedisCache'
		resourceName: resource.name
		location: location
		privateDnsResourceId: privateRedisCacheDnsModule.outputs.privateDnsResourceId
		resourceTags: resourceTags
		subnetResourceId: redisCacheSubnetResource.id
		resourceRg: resource.rg
		subscriptionId: resource.subId
	}
}]

module peExistingWebsiteModule '../modules/peExistingWebsite.bicep' = [for resource in WebSites : if (resource.kind == 'app') {
	name: '${resource.name}-WebSite-pe-module'
	params: {
		dnsConfig: 'WebSite'
		resourceName: resource.name
		location: location
		privateDnsResourceId: privateWebSiteDnsModule.outputs.privateDnsResourceId
		resourceTags: resourceTags
		subnetResourceId: servicesSubnetResource.id
		resourceRg: resource.rg
		subscriptionId: resource.subId
	}
}]

//End of Private endpoints creation section 
