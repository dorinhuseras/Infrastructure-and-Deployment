// Parameters Definition section 
param location string = resourceGroup().location

@allowed(['Dev','Prod','Test'])
@description('Environment name, should be set as a pipeline variable. Default value is Dev')
param environmentType string = 'Prod'

@description('Project name, should be set as a pipeline variable')
param projectName string

@description('VNet definition object')
param vnet object

param appServicePlans array = []

@description('An object array with the app services that will be instantiated')
param appServices array = []

param storageAccounts array = []

param sqlServers array = []

param sqlDatabases array = [] 

param serviceBuses array = []

param cosmosServers array = []

param redisCaches array = []

param tenants array = []

param keyvault object


param resourceTags object = {
  EnvironmentName: environmentType
  Project: projectName
  DeploymentType: 'Bicep'
}

@description('Set this to true only on the first deployment of the template. It is used for Vnet Dns Link, that can happen only one time')
param newEnvironment bool = true

param createResources bool = true

param createPrivateEndpoints bool = false

param configureMis bool = false

param useUamiConnection bool = true

param saveSecrets bool = true

//End of Parameters Definition section 

module initializerModule 'agregationModules/initializerModule.bicep' = {
  name: 'parametersInitializer-module'
  params: {
    vnet: vnet
    keyvault: keyvault
    projectName: projectName
    appServicePlans: appServicePlans
    appServices: appServices
    environmentType: environmentType
    storageAccounts: storageAccounts
    sqlServers: sqlServers
    sqlDatabases: sqlDatabases
    serviceBuses: serviceBuses
    cosmosServers: cosmosServers
    redisCaches: redisCaches
    tenants: tenants
  }
}

//Resource creation section
module resourceGenerationModule 'agregationModules/resourcesGeneratorModule.bicep' = if (createResources == true){
  name: 'resourceGeneration-module'
  dependsOn: [initializerModule]
  params: {
    location: location
    resourceTags: resourceTags
    environmentType: environmentType
    vnet: initializerModule.outputs.vnet
    appServicePlans: initializerModule.outputs.appServicePlans
    appServices: initializerModule.outputs.appServices
    managedIdentities: initializerModule.outputs.managedIdentities
    storageAccounts: initializerModule.outputs.storageAccounts
    sqlServers: initializerModule.outputs.sqlServers
    sqlDatabases: initializerModule.outputs.sqlDatabases
    serviceBuses: initializerModule.outputs.serviceBuses
    redisCaches: initializerModule.outputs.redisCaches
    cosmosServers: initializerModule.outputs.cosmosServers
    keyvault: initializerModule.outputs.keyVault
    projectName: projectName
    newEnvironment: newEnvironment
  }
}
//End of Resource creation section


//Private DNS & PE creation section
module peGenerationModule 'agregationModules/privateEndpointsModule.bicep' = if (createPrivateEndpoints == true) {
  name: 'peGeneration-module'
  dependsOn: [initializerModule, resourceGenerationModule]
  params: {
    location: location
    resourceTags: resourceTags
    vnet: initializerModule.outputs.vnet
    storageAccounts: initializerModule.outputs.storageAccounts
    sqlServers: initializerModule.outputs.sqlServers
    redisCaches: initializerModule.outputs.redisCaches
    cosmosServers: initializerModule.outputs.cosmosServers
    WebSites: initializerModule.outputs.appServices
    keyvaults: [initializerModule.outputs.keyVault]
  }
}
//End of DNS & PE creation section


//Secret writer section
module secretGenerationModule 'agregationModules/secretsGeneratorModule.bicep' = if (saveSecrets == true) {
  name: 'secretGeneration-module'
  dependsOn: [initializerModule, resourceGenerationModule]
  params: {
    location: location
    useUamiConnection: useUamiConnection
    projectName: projectName
    storageAccounts: initializerModule.outputs.storageAccounts
    sqlDatabases: initializerModule.outputs.sqlDatabases
    serviceBuses: initializerModule.outputs.serviceBuses
    redisCaches: initializerModule.outputs.redisCaches
    managedIdentities: initializerModule.outputs.managedIdentities
    keyvault: initializerModule.outputs.keyVault
  }
}
//End of Secret writer section


//Set MIs section
module setMisOnAppsModules 'agregationModules/iamModule.bicep' = if (configureMis == true) {
  name: 'setMisOnApps-module'
  dependsOn: [initializerModule, resourceGenerationModule]
  params: {
    location: location
    managedIdentities: initializerModule.outputs.managedIdentities
    appServices: initializerModule.outputs.appServices
    resourceTags: resourceTags
  }
}
//Endo of Set MIs section


output tenants array = initializerModule.outputs.tenatnsFromDb
output keyvaultName string = initializerModule.outputs.keyVault.name
output sqlServersNames array = initializerModule.outputs.sqlServers
