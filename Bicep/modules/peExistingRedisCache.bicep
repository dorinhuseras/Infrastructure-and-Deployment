param resourceName string
param resourceRg string
param subscriptionId string 
param location string
param resourceTags object
param privateDnsResourceId string 
param subnetResourceId string

@allowed(['RedisCache'])
param dnsConfig string

resource redisCacheResource 'Microsoft.Cache/redis@2022-06-01' existing = {
	name: resourceName
	scope: resourceGroup(subscriptionId, resourceRg)
}

module StorageTablePrivateEndpointModule 'privateendpoint.bicep' = {
  name: '${resourceName}${dnsConfig}-pe-module'
  params: {
    dnsConfig: dnsConfig
    location: location
    privateDnsResourceId: privateDnsResourceId 
    resourceTags: resourceTags
    resourceId: redisCacheResource.id
    resourceName: '${redisCacheResource.name}${dnsConfig}'
    subnetResourceId: subnetResourceId 
  }
}
