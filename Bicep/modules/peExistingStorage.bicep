param resourceName string
param resourceRg string 
param subscriptionId string 
param location string
param resourceTags object
param privateDnsResourceId string 
param subnetResourceId string

@allowed(['StorageTable','StorageBlob'])
param dnsConfig string

resource tableStorageResource 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
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
    resourceId: tableStorageResource.id
    resourceName: '${tableStorageResource.name}${dnsConfig}'
    subnetResourceId: subnetResourceId 
  }
}
