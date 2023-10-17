@description('Location for all resources.')
param location string = resourceGroup().location

param resourceTags object

@allowed(['Enabled','Disabled'])
param publicNetworkAccess string = 'Enabled'

@description('The name of the SQL logical server.')
param databaseServerName string 

param firewallRules array = []

param azureADOnlyAuthentication bool = true

resource sqlServerResource 'Microsoft.Sql/servers@2022-05-01-preview' ={
  name: databaseServerName
  tags: resourceTags
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    minimalTlsVersion: '1.2'
    publicNetworkAccess: publicNetworkAccess
    restrictOutboundNetworkAccess: 'Disabled'
    version: '12.0'
    administrators: {
      login: 'SQL Server Admins'
      administratorType: 'ActiveDirectory'
      principalType: 'Group'
      sid: '7f85ccb4-016f-4c94-b902-2b07b87dbae5'
      tenantId: subscription().tenantId
      azureADOnlyAuthentication: azureADOnlyAuthentication
    }
  }
}

resource firewallRule 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = [for firewallRule in firewallRules : {
  name: firewallRule.name 
  parent: sqlServerResource
  properties: {
    endIpAddress: firewallRule.endIpAddress
    startIpAddress: firewallRule.startIpAddress
  }
}]

output sqlServerResourceId string = sqlServerResource.id
output sqlServerResourceName string = sqlServerResource.name
