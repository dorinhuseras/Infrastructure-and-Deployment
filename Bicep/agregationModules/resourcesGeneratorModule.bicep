param location string = resourceGroup().location

@allowed(['Dev','Prod','Test'])
@description('Environment name, should be set as a pipeline variable. Default value is Dev')
param environmentType string

@description('Project name, should be set as a pipeline variable')
param projectName string

param resourceTags object = {}

param storageAccounts array = []

param sqlServers array = []

param cosmosServers array = []

param redisCaches array = []

param keyvault object

param newEnvironment bool

param sqlDatabases array = [] 

param serviceBuses array = []

param appServicePlans array = []

param managedIdentities array = []

@description('An object array with the app services that will be instantiated')
param appServices array = []

@description('VNet definition object')
param vnet object


module environmentIpRestrictions '../modules/environmentIpRestrictions.bicep' = {
 name: 'environmentIpRestrictions-module'
 params: {
   environmentType: environmentType
 }
}
//End of Prepare dependencies section


//Resource creation section
module virtualNetworkModule '../modules/virtualnetwork.bicep' = if (length(appServicePlans) > 0) {
  name: '${projectName}-vnet-module'
  params:{
   virtualNetworkName: vnet.name
   location: location
   resourceTags: resourceTags
   vnetAddressSpaces: vnet.vnetAddressSpaces
   subnets: vnet.subnets
  }
}

module managedIdentitiesModule '../modules/managedIdentity.bicep' = [for resource in managedIdentities: if (length(appServices) > 0) {
  name: '${resource.tenant}-mi-module'
  params: {
    location: location
    name: resource.miName
    resourceTags: resourceTags
  }
}]

module appServicePlanModules '../modules/appServicePlan.bicep' = [for resource in appServicePlans: {
  name: '${resource.name}-sp-module'
  scope: resourceGroup(resource.subId, resource.rg)
  params: {
    location: location
    resourceTags: resourceTags
    name: '${resource.name}'
    sku: resource.sku
  }
}]

module appServiceModule '../modules/appService.bicep' = [ for resource in appServices : {
  name: '${resource.name}-as-module'
  dependsOn: [appServicePlanModules]
  scope: resourceGroup(resource.subId, resource.rg)
  params: {
    location: location
    ipSecurityRestrictions: environmentIpRestrictions.outputs.appServiceIpRestrictions
    netFrameworkVersion: resource.netFrameworkVersion
    kind: resource.kind
    appServiceName: resource.name
    appServiceSubnetName: resource.vNetIntegrationSubnet
    resourceTags: resourceTags
    servicePlanName: resource.spName
    servicePlanResourceGrup: resource.spRg
    servicePlanSubscriptionId: resource.spSubId
  }
}]

module storageModules '../modules/storageAccount.bicep' = [for resource in storageAccounts: {
  name: '${resource.name}-module'
  scope: resourceGroup(resource.subId, resource.rg)
  params: {
    storageAccountName: resource.name
    location: location
    kind: resource.kind
    projectName: projectName
    resourceTags: union(resourceTags, resource.resourceTags)
    tables: resource.tables
    blobs: resource.blobs
    skuName: resource.sku.name
    publicNetworkAccess: resource.properties.publicNetworkAccess
    networkAcls: resource.properties.networkAcls
  }
}]

module sqlServerModuleNew '../modules/sqlServernew.bicep' = [ for resource in sqlServers: if (newEnvironment) {
  name: '${resource.name}-sqlserverNew-module'
  scope: resourceGroup(resource.subId, resource.rg)
  params: {
    location: location
    administratorLogin: projectName
    administratorLoginPassword: 'SecretPassword'
    resourceTags: resourceTags
    databaseServerName: resource.name
    firewallRules: environmentIpRestrictions.outputs.databaseIpRestrictions
    publicNetworkAccess: resource.publicNetworkAccess
  }
}]

module sqlServerModule '../modules/sqlServer.bicep' = [ for resource in sqlServers: if (!newEnvironment) {
  name: '${resource.name}-sqlserver-module'
  scope: resourceGroup(resource.subId, resource.rg)
  params: {
    location: location
    resourceTags: resourceTags
    databaseServerName: resource.name
    firewallRules: environmentIpRestrictions.outputs.databaseIpRestrictions
    publicNetworkAccess: resource.publicNetworkAccess
  }
}]

module sqlDatabaseModule '../modules/sqlDatabase.bicep' = [ for resource in sqlDatabases: {
  name: '${resource.name}-db-module'
  dependsOn: [sqlServerModuleNew, sqlServerModule]
  scope: resourceGroup(resource.subId, resource.rg)
  params: {
    location: location
    name: resource.name
    sku: resource.sku
    parentName: resource.parentName
    maxSizeBytes: resource.maxSizeBytes
    requestedBackupStorageRedundancy: resource.requestedBackupStorageRedundancy
  }
}]

module serviceBusNamescpaceModule '../modules/serviceBus.bicep' = [ for resource in serviceBuses: {
  name: '${resource.name}-servicebus-module'
  scope: resourceGroup(resource.subId, resource.rg)
  params: {
    location: location
    name: resource.name
    resourceTags: resourceTags
    sku: resource.sku
  }
}]


module cosmosDbTableModule '../modules/cosmostable.bicep'= [for resource in cosmosServers: {
  name: '${resource.name}-cosmos-module'
  scope: resourceGroup(resource.subId, resource.rg)
  params: {
    cosmosDbName: resource.name
    location: location
    resourceTags: resourceTags
  }
}]

module redisCacheModule '../modules/redisCache.bicep' = [for resource in redisCaches : {
  name: '${resource.name}-module'
  scope: resourceGroup(resource.subId, resource.rg)
  params: {
    name: resource.name
    location: location
    capacity: resource.capacity
    family: resource.family
    resourceTags: resourceTags
    skuName: resource.skuName
  }
}]


module keyvaultAccessPolicy '../modules/keyvaultAccessPolicy.bicep' = if (length(appServices) > 0) {
  name: 'appservice-keyvaultAccessPolicy'
  dependsOn: [appServiceModule]
  params: {
    appServices: appServices
  }
}

module keyValutModule  '../modules/keyvault.bicep' = {
  name: '${keyvault.name}-module'
  dependsOn: [keyvaultAccessPolicy]
  scope: resourceGroup(keyvault.subId, keyvault.rg)
  params: {
    resourceTags: resourceTags
    location: location
    accessPolicies:  length(appServices) > 0 ? concat(keyvaultAccessPolicy.outputs.accessPolicy, keyvault.accessPolicy) : keyvault.accessPolicy
    publicNetworkAccess: keyvault.publicNetworkAccess
    keyVaultName: keyvault.name
  }
}
//End of Resource creation section
