param location string

param appServiceName string

param managedIdentities array = []


var miIds = reduce(managedIdentities, {}, (cur, next) => union(cur, {
  '${next.id}': {}
}))

resource appServiceAppResource 'Microsoft.Web/sites@2022-03-01' = {
  name: appServiceName
  location: location
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: miIds
  }
  properties: {
  }
}
output rez object =  miIds
output appMis object = appServiceAppResource.identity.userAssignedIdentities
