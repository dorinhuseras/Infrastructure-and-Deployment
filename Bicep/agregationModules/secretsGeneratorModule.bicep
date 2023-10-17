param location string

@description('Project name, should be set as a pipeline variable')
param projectName string

param storageAccounts array = []

param sqlDatabases array = [] 

param serviceBuses array = []

param cosmosServers array = []

param redisCaches array = []

param managedIdentities array = []

param keyvault object

param environmentName string = projectName

param useUamiConnection bool

//Secret writer section
module keyVaultRedisCacheSecretWriter '../modules/keyVaultRedisCacheSecretWriter.bicep' = [for resource in redisCaches : {
  name: '${resource.name}-redis-scrtwr-module'
  params: {
    keyVaultName: keyvault.name
    secretName:  '${environmentName}-${resource.secretSuffix}'
    redisCacheName: resource.name
    resourceRg: resource.rg
    resourceSubId: resource.subId
  }
}]

module keyVaultBlobSecretWriter '../modules/keyVaultStorageSecretWriter.bicep' = [for resource in storageAccounts : if (resource.tenant != '') {
  name: '${resource.name}-blob-scrtwr-module'
  params: {
    keyVaultName: keyvault.name
    secretName: '${resource.tenant}-Blob${resource.secretSuffix}'
    storageName: resource.name
    resourceRg: resource.rg
    resourceSubId: resource.subId
  }
}]

module keyVaultTableSecretWriter '../modules/keyVaultStorageSecretWriter.bicep' = [for resource in storageAccounts : {
  name: '${resource.name}-table-scrtwr-module'
  params: {
    keyVaultName: keyvault.name
    secretName:  resource.tenant == '' ? '${environmentName}-MasterConnection': '${resource.tenant}-Table${resource.secretSuffix}'
    storageName: resource.name
    resourceRg: resource.rg
    resourceSubId: resource.subId
  }
}]

module keyVaultCosmosStorageSecretWriter '../modules/keyVaultCosmosStorageSecretWriter.bicep' = [for resource in cosmosServers : {
  name: '${resource.name}-cosmos-scrtwr-module'
  params: {
    keyVaultName: keyvault.name
    secretName: '${resource.tenant}-Table${resource.secretSuffix}'
    cosmosName: resource.name
    resourceRg: resource.rg
    resourceSubId: resource.subId
  }
}]

module keyVaultServiceBusSecretWriter '../modules/keyVaultServiceBusSecretWriter.bicep' = [for resource in serviceBuses : {
  name: '${resource.name}-servicebus-scrtwr-module'
  params: {
    keyVaultName: keyvault.name
    secretName: '${environmentName}-${resource.secretSuffix}'
    serviceBusName: resource.name
    resourceRg: resource.rg
    resourceSubId: resource.subId
  }
}]

module keyVaultDbSecretWriter '../modules/keyVaultDbSecretWriter.bicep' = [for resource in sqlDatabases: {
  name: '${resource.name}-db-scrtwr-module'
  params: {
    keyVaultName: keyvault.name
    secretName: '${resource.tenant}-${resource.secretSuffix}'
    sqlDatabaseName: resource.name
    sqlServerName: resource.parentName
    resourceRg: resource.rg
    resourceSubId: resource.subId
    useUamiConnection: useUamiConnection
  }
}]

module keyVaultManagedIdentityWriter '../modules/keyVaultManagedIdentitySecretWriter.bicep' = [for resource in managedIdentities: {
  name: '${resource.tenant}-mi-scrtwr-module'
  params: {
    location: location
    keyVaultName: keyvault.name
    secretName: '${resource.tenant}-${resource.secretSuffix}'
    managedIdentityName: resource.miName
  }
}]
//End of Secret writer section
