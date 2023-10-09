param resourceName string
param resourceRg string 
param subscriptionId string 
param location string
param resourceTags object

param privateDnsResourceId string 
param subnetResourceId string

@allowed(['SqlServer'])
param dnsConfig string

resource sqlServerResource 'Microsoft.Sql/servers@2021-11-01' existing = {
	name: resourceName
	scope: resourceGroup(subscriptionId ,resourceRg)
}

module StorageTablePrivateEndpointModule 'privateendpoint.bicep' = {
  name: '${resourceName}${dnsConfig}-pe-module'
  params: {
    dnsConfig: dnsConfig
    location: location
    privateDnsResourceId: privateDnsResourceId 
    resourceTags: resourceTags
    resourceId: sqlServerResource.id
    resourceName: '${sqlServerResource.name}${dnsConfig}'
    subnetResourceId: subnetResourceId 
  }
}
