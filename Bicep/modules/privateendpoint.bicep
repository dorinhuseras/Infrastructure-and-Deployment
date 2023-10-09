param location string = resourceGroup().location

@description('A name used for the PE and the DNS link')
param resourceName string

@description('Resorce for witch you want to create the PE')
param resourceId string

@description('Each PE must pe registerd on a DNS server so that it can be accesed by the services using the DNS record name')
param privateDnsResourceId string 

@description('Provide the subnet Id where the private endpoint will be created.')
param subnetResourceId string

@allowed(['StorageTable','StorageBlob','SqlServer','CosmosTable','KeyVault', 'WebSite','RedisCache'])
param dnsConfig string

param resourceTags object

@description('Define the SKUs for each component based on the environment type.')
var dnsTypeConfigurationMap = {
  StorageTable: {
      DnsName: 'privatelink.table.${environment().suffixes.storage}'
      GroupIds: 'Table'
  }
  StorageBlob: {
      DnsName: 'privatelink.blob.${environment().suffixes.storage}'
      GroupIds: 'Blob'
  }
  SqlServer:{
      DnsName: 'privatelink${environment().suffixes.sqlServerHostname}'
      GroupIds: 'SqlServer'
  }
  CosmosTable: {
      DnsName: 'privatelink.table.cosmos.azure.com'
      GroupIds: 'Table'
  }
  KeyVault: {
    DnsName: 'privatelink.vaultcore.azure.net'
    GroupIds: 'vault'
  }
  WebSite: {
    DnsName: 'privatelink.azurewebsites.net'
    GroupIds: 'sites'
  }
  RedisCache: {
    DnsName: 'privatelink.redis.cache.windows.net'
    GroupIds: 'redisCache'
  }
}


resource resourcePrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-05-01' = {
  name: '${resourceName}-pe'
  location: location
  tags: resourceTags
  properties: {
    privateLinkServiceConnections:[
      {
        name: '${resourceName}-pe'
        properties:{
          privateLinkServiceId: resourceId
          groupIds: [
            dnsTypeConfigurationMap[dnsConfig].GroupIds
          ]
        }
      }
    ]
    subnet: {
      id: subnetResourceId
    }
  }
}

resource privateEndpointDnsLink 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-05-01' = {
  name: '${resourceName}-pe-dns'
  parent: resourcePrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name:dnsTypeConfigurationMap[dnsConfig].DnsName
        properties: {
          privateDnsZoneId: privateDnsResourceId
        }
      }
    ]
  }
}
