param resourceName string
param resourceRg string 
param subscriptionId string 
param location string
param resourceTags object
param privateDnsResourceId string 
param subnetResourceId string

@allowed(['WebSite'])
param dnsConfig string

resource appServiceAppResource 'Microsoft.Web/sites@2022-03-01' existing = {
	name: resourceName
	scope: resourceGroup(subscriptionId, resourceRg)
}

module webSitePrivateEndpointModule 'privateendpoint.bicep' = {
  name: '${resourceName}${dnsConfig}-pe-module'
  params: {
    dnsConfig: dnsConfig
    location: location
    privateDnsResourceId: privateDnsResourceId 
    resourceTags: resourceTags
    resourceId: appServiceAppResource.id
    resourceName: '${appServiceAppResource.name}${dnsConfig}'
    subnetResourceId: subnetResourceId 
  }
}
