param location string

param resourceTags object

@allowed(['Enabled','Disabled'])
param publicNetworkAccess string = 'Disabled'

param cosmosDbName string 

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-03-15' = {
  name: cosmosDbName
  location: location
  kind: 'GlobalDocumentDB'
  tags: resourceTags
  properties: {
    publicNetworkAccess: publicNetworkAccess
    defaultIdentity: 'FirstPartyIdentity'
    consistencyPolicy: {
      defaultConsistencyLevel: 'BoundedStaleness'
      maxStalenessPrefix: 1000000
      maxIntervalInSeconds: 86400
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
    capabilities: [
      {
        name: 'EnableTable'
      }
    ]
  }
}

output cosmosDbAccountId string = cosmosDbAccount.id
output cosmosDbAccountName string = cosmosDbAccount.name
