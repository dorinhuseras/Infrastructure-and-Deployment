param location string

param name string

param resourceTags object

@allowed([0,1,2,3,4,5,6])
param capacity int

@allowed(['C','P'])
param family string

@allowed(['Basic','Premium', 'Standard'])
param skuName string

@allowed(['Disabled','Enabled'])
param publicNetworkAccess string = 'Disabled'


resource redisCacheResource 'Microsoft.Cache/redis@2022-06-01' = {
  name: name
  location: location
  tags: resourceTags
  properties: {
    publicNetworkAccess: publicNetworkAccess
    sku: {
      capacity: capacity
      family: family
      name: skuName
    }
  }
}

output redisCacheResourceId string = redisCacheResource.id
output redisCacheResourceName string = redisCacheResource.name
