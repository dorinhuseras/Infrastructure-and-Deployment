param location string
param name string
param resourceTags object

resource managedIdentiy 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
  tags: resourceTags
}

output managedIdentityId string = managedIdentiy.properties.clientId
output managedIdentityResourceId string = managedIdentiy.id
