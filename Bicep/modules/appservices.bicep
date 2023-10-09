param location string

@description('An array with the app services names that will be instantiated')
param appServicesAppNames array

param resourceTags object

param environmentName string

param vnetIntegrationSubnet string = ''

param sevicePlanId string = ''


@description('Define the SKUs for each component based on the environment type.')
var environmentConfigurationMap = {
  Prod: {
    appServicePlan: {
      sku: {
        name: 'p1v2'
        capacity: 1
      }
    }
  }
  Dev: {
    appServicePlan: {
      sku: {
        name: 'p1v2'
        capacity: 1
      }
    }
  }
}

@description('Project name')
param projectName string

@description('Custom name for the App service plan used for App Services')
param appServicePlanName string = '${environmentName}-${projectName}-sp'


resource appServicePlan 'Microsoft.Web/serverFarms@2022-03-01' = if (sevicePlanId == ''){
  name: appServicePlanName
  location: location
  tags: resourceTags
  sku: environmentConfigurationMap[environmentName].appServicePlan.sku
  kind: 'windows'
}

resource appServiceAppResources 'Microsoft.Web/sites@2022-03-01' = [for appServiceAppName in appServicesAppNames: {
  name: appServiceAppName
  location: location
  tags: resourceTags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: sevicePlanId == '' ? appServicePlan.id : sevicePlanId
    httpsOnly: true
    siteConfig: {
      http20Enabled: true

      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      use32BitWorkerProcess: false
      netFrameworkVersion: 'v4.8'
      phpVersion: 'Off'
      remoteDebuggingEnabled: false
      webSocketsEnabled: true
      alwaysOn: true
      minimumElasticInstanceCount: 0
    }
    virtualNetworkSubnetId: vnetIntegrationSubnet!= '' ? vnetIntegrationSubnet : null
    vnetRouteAllEnabled: false
  }
}]
