param appServices array

resource appServicesResources  'Microsoft.Web/sites@2022-03-01' existing = [ for resource in appServices: {
  name: resource.name
}]

output accessPolicy array = [for i in range (0, length(appServices)): {
  objectId: appServicesResources[i].identity.principalId
  permissions: {
    secrets: ['get']
  }
  tenantId: subscription().tenantId
}]
