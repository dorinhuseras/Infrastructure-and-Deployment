param resourceName string
param resourceRg string 
param subscriptionId string 
param location string
param resourceTags object
param privateDnsResourceId string 
param subnetResourceId string

@allowed(['KeyVault'])
param dnsConfig string


resource keyVaultResoure 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
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
    resourceId: keyVaultResoure.id
    resourceName: '${keyVaultResoure.name}${dnsConfig}'
    subnetResourceId: subnetResourceId 
  }
}
