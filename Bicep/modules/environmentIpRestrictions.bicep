@allowed(['Dev','Prod','Test'])
@description('Environment name, should be set as a pipeline variable. Default value is Dev')
param environmentType string


var ipSecurityEnvRestrictions = {
  Dev: [
    {
      ipAddress: 'Any'
      action: 'Allow'
      priority: 2147483647
      name: 'Allow all'
    }
  ]
  Test: [
    {
      ipAddress: 'Any'
      action: 'Allow'
      priority: 2147483647
      name: 'Allow all'
    }
  ]
  Prod: [
    {
      ipAddress: 'Any'
      action: 'Allow'
      priority: 2147483647
      name: 'Allow all'
    }
  ]
  } 

  var firewallRules = {
  Dev: [
    {
      name: 'Home'
      startIpAddress: '188.27.130.58'
      endIpAddress: '188.27.130.58'
    }
  ]
  Test: [
    {
      name: 'Home'
      startIpAddress: '188.27.130.58'
      endIpAddress: '188.27.130.58'
    }
  ]
  Prod: [
    {
      name: 'Home'
      startIpAddress: '188.27.130.58'
      endIpAddress: '188.27.130.58'
    }
  ]
}

output appServiceIpRestrictions array = ipSecurityEnvRestrictions[environmentType] 
output databaseIpRestrictions array = firewallRules[environmentType] 
