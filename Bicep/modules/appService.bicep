param location string

param resourceTags object

param appServiceSubnetName string

param appServiceName string

param servicePlanName string

param servicePlanResourceGrup string

param servicePlanSubscriptionId string

param ipSecurityRestrictions array = []

@allowed(['functionapp','app'])
param kind string

@allowed(['v4.0','v6.0'])
param netFrameworkVersion string

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' existing = {
  name: servicePlanName
  scope: resourceGroup(servicePlanSubscriptionId, servicePlanResourceGrup)
}

resource appServiceVnetIntegrationSubnetResource 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' existing = if (appServiceSubnetName != '') {
  name: appServiceSubnetName
}

resource appServiceAppResource 'Microsoft.Web/sites@2022-09-01' = {
  name: appServiceName
  location: location
  tags: resourceTags
  kind: kind
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: false
    siteConfig: {
      http20Enabled: true
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      use32BitWorkerProcess: false
      netFrameworkVersion: netFrameworkVersion
      phpVersion: 'Off'
      remoteDebuggingEnabled: false
      webSocketsEnabled: true
      alwaysOn: true
      minimumElasticInstanceCount: 0
      ipSecurityRestrictions: ipSecurityRestrictions
      publicNetworkAccess: 'Enabled'
    }
    publicNetworkAccess: 'Enabled'
    virtualNetworkSubnetId: appServiceVnetIntegrationSubnetResource.id
    vnetRouteAllEnabled: true
  }
}

output id string = appServiceAppResource.id
output name string = appServiceAppResource.name
output principalId string = appServiceAppResource.identity.principalId
