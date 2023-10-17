@description('VNet definition object')
param vnet object

param environmentType string

param appServicePlans array = []

@description('An object array with the app services that will be instantiated')
param appServices array = []

param storageAccounts array = []

param sqlServers array = []

param sqlDatabases array = [] 

param serviceBuses array = []

param cosmosServers array = []

param redisCaches array = []

param keyvault object

param tenants array = []

param projectName string

var virtualNetworkName = '${environmentType}-${projectName}-vnet'

var lowerProjectName = toLower(projectName)

var tenatnsFromDefinition = [for resource in tenants: {
  tenant: resource
  miName: '${resource}Uami'
  secretSuffix: 'managedIdentityClientId'
}]

output vnet object = {
  name: virtualNetworkName
  vnetAddressSpaces: vnet.vnetAddressSpaces
  subnets: vnet.subnets
}

output appServicePlans array = [for resource in appServicePlans: {
  name: !contains(resource,'name') ? '${resource.prefix}${projectName}${resource.suffix}': resource.name
  sku: resource.sku
  rg: contains(resource,'rg') ? resource.rg : resourceGroup().name
  subId: contains(resource,'subId') ? resource.subId : subscription().subscriptionId
}]

output appServices array = [for resource in appServices: {
  name: !contains(resource,'name') ? '${resource.prefix}${projectName}${resource.suffix}': resource.name
  kind: contains(resource,'kind') ? resource.kind : 'app'
  netFrameworkVersion: contains(resource,'netFrameworkVersion') ? resource.netFrameworkVersion : 'v4.0'
  rg: contains(resource,'rg') ? resource.rg : resourceGroup().name
  subId: contains(resource,'subId') ? resource.subId : subscription().subscriptionId
  spName: !contains(resource,'spName') ? '${resource.spPrefix}${projectName}${resource.spSuffix}': resource.spName
  spRg: contains(resource,'spRg') ? resource.spRg : resourceGroup().name
  spSubId: contains(resource,'spSubId') ? resource.spSubId : subscription().subscriptionId
  vNetIntegrationSubnet: '${virtualNetworkName}/${resource.vNetIntegrationSubnet}'
}]

output storageAccounts array = [for resource in storageAccounts: {
  name: !contains(resource,'name') ? (contains(resource,'tenant') ? '${lowerProjectName}${resource.prefix}${toLower(resource.tenant)}${resource.suffix}' : '${resource.prefix}${lowerProjectName}${resource.suffix}'): resource.name
  tenant: contains(resource,'tenant') ? resource.tenant : ''
  secretSuffix: resource.secretSuffix
  blobs: resource.blobs
  shares: resource.shares
  tables: resource.tables
  kind: resource.kind
  sku: resource.sku
  properties: resource.properties
  resourceTags: resource.resourceTags
  rg: contains(resource,'rg') ? resource.rg : resourceGroup().name
  subId: contains(resource,'subId') ? resource.subId : subscription().subscriptionId
}]

output sqlServers array = [for resource in sqlServers: {
  name: !contains(resource,'name') ? '${resource.prefix}${projectName}${resource.suffix}' : resource.name
  publicNetworkAccess: resource.publicNetworkAccess
  rg: contains(resource,'rg') ? resource.rg : resourceGroup().name
  subId: contains(resource,'subId') ? resource.subId : subscription().subscriptionId
}]

var sqlDatabasesResult  = [for resource in sqlDatabases: {
  tenant: resource.tenant
  name: !contains(resource,'name') ? '${projectName}${resource.prefix}${resource.tenant}${resource.suffix}' : resource.name
  secretSuffix: resource.secretSuffix
  sku: resource.sku
  rg: contains(resource,'rg') ? resource.rg : resourceGroup().name
  subId: contains(resource,'subId') ? resource.subId : subscription().subscriptionId
  parentName: !contains(resource,'parentName') ? '${resource.parentPrefix}${projectName}${resource.parentSuffix}' : resource.parentName
  maxSizeBytes: resource.maxSizeBytes
  requestedBackupStorageRedundancy: resource.requestedBackupStorageRedundancy
}]

output sqlDatabases array = sqlDatabasesResult

var tenatnsFromDb = [for resource in sqlDatabasesResult: {
  tenant: resource.tenant
  miName: '${resource.tenant}Uami'
  secretSuffix: 'managedIdentityClientId'
  sqlServerName: resource.parentName
  sqlDatabaseName: resource.name
}]

output serviceBuses array = [for resource in serviceBuses: {
  name: !contains(resource,'name') ? '${resource.prefix}${projectName}${resource.suffix}' : resource.name
  secretSuffix: resource.secretSuffix
  sku: resource.sku
  rg: contains(resource,'rg') ? resource.rg : resourceGroup().name
  subId: contains(resource,'subId') ? resource.subId : subscription().subscriptionId
}]

output cosmosServers array = [for resource in cosmosServers: {
  name: !contains(resource,'name') ? '${lowerProjectName}${resource.prefix}${resource.tenant}${resource.suffix}' : resource.name
  tenant: resource.tenant
  secretSuffix: resource.secretSuffix
  rg: contains(resource,'rg') ? resource.rg : resourceGroup().name
  subId: contains(resource,'subId') ? resource.subId : subscription().subscriptionId
}]

output redisCaches array = [for resource in redisCaches: {
  name: !contains(resource,'name') ? '${resource.prefix}${projectName}${resource.suffix}' : resource.name
  secretSuffix: resource.secretSuffix
  capacity: resource.capacity
  family: resource.family
  skuName: resource.skuName
  rg: contains(resource,'rg') ? resource.rg : resourceGroup().name
  subId: contains(resource,'subId') ? resource.subId : subscription().subscriptionId
}]

output keyVault object = {
  name: !contains(keyvault,'name') ? '${keyvault.prefix}${projectName}${keyvault.suffix}' : keyvault.name
  publicNetworkAccess: keyvault.publicNetworkAccess
  accessPolicy: keyvault.accessPolicy
  subnets: vnet.subnets
  rg: contains(keyvault,'rg') ? keyvault.rg : resourceGroup().name
  subId: contains(keyvault,'subId') ? keyvault.subId : subscription().subscriptionId
}

output managedIdentities array = tenants != [] ? tenatnsFromDefinition : tenatnsFromDb

output tenatnsFromDb array = tenatnsFromDb
