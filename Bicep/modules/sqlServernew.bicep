@description('Location for all resources.')
param location string = resourceGroup().location

param resourceTags object

@allowed(['Enabled','Disabled'])
param publicNetworkAccess string = 'Enabled'

@description('The name of the SQL logical server.')
param databaseServerName string 

param firewallRules array = []

@description('The administrator username of the SQL logical server.')
param administratorLogin string

@description('The administrator password of the SQL logical server.')
@secure()
param administratorLoginPassword string

param azureADOnlyAuthentication bool = false

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
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    administrators: {
      login: 'SQL Server Admins'
      administratorType: 'ActiveDirectory'
      principalType: 'Group'
      sid: 'f0d44e85-bb14-4e9c-bed2-7e65d44712ac'
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
