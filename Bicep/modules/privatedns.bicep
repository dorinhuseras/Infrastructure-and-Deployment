param resourceName string 

param resourceTags object

@description('Use virtualNetwrokId to link the private DNS to the VNet, just make sure that the link does not aleady exists')
param virtualNetwrokId string 

@allowed(['StorageTable','StorageBlob','SqlServer','CosmosTable','KeyVault','WebSite','RedisCache'])
param dnsConfig string

@description('Define the SKUs for each component based on the environment type.')
var dnsConfigurationMap = {
  StorageTable: {
      DnsName: 'privatelink.table.${environment().suffixes.storage}'
  }
  StorageBlob: {
      DnsName: 'privatelink.blob.${environment().suffixes.storage}'
  }
  SqlServer:{
      DnsName: 'privatelink${environment().suffixes.sqlServerHostname}'
  }
  CosmosTable: {
      DnsName: 'privatelink.table.cosmos.azure.com'
  }
  KeyVault: {
    DnsName: 'privatelink.vaultcore.azure.net'
  }
  WebSite: {
    DnsName: 'privatelink.azurewebsites.net'
  }
  RedisCache: {
    DnsName: 'privatelink.redis.cache.windows.net'
  }
}


resource privateDnsResource 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: dnsConfigurationMap[dnsConfig].DnsName
  tags: resourceTags
  location: 'global'
}

resource resourcePrivateDnsNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
 name: '${resourceName}-dns-link'
 location: 'global'
 parent: privateDnsResource
 properties: {
  registrationEnabled: false
  virtualNetwork: {
    id: virtualNetwrokId
  }
 }
}

output privateDnsResourceId string = privateDnsResource.id
