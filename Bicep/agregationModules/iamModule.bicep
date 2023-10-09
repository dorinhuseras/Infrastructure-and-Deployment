param managedIdentities array
param location string
@description('An object array with the app services that will be instantiated')
param appServices array 
param resourceTags object


module managedIdentitiesModule '../modules/managedIdentity.bicep' = [for resource in managedIdentities: if (length(appServices) > 0) {
  name: '${resource.tenant}-iammi-module'
  params: {
    location: location
    name: resource.miName
    resourceTags: resourceTags
  }
}]

module appServicesMi '../modules/appSerivceIdentity.bicep' = [ for resource in appServices : {
  name : '${resource.name}-mi-module'
  dependsOn: [managedIdentitiesModule]
  params: {
    location: location
    appServiceName: resource.name
    managedIdentities: [for i in range(0,length(managedIdentities)) : {
      id: managedIdentitiesModule[i].outputs.managedIdentityResourceId
    }]
  }
}]
