param resourceName string
param resourceRg string
param subscriptionId string 
param location string
param resourceTags object
param privateDnsResourceId string 
param subnetResourceId string

@allowed(['CosmosTable'])
param dnsConfig string

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-03-15' existing = {
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
    resourceId: cosmosDbAccount.id
    resourceName: '${cosmosDbAccount.name}${dnsConfig}'
    subnetResourceId: subnetResourceId 
  }
}
