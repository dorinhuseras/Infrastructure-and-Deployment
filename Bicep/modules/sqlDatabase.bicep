param name string
param location string
param parentName string
param sku object
param maxSizeBytes string 
param requestedBackupStorageRedundancy string

resource sqlServerResource 'Microsoft.Sql/servers@2022-05-01-preview' existing = {
  name: parentName
}

resource sqlDatabase  'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  name: name
  location: location
  parent: sqlServerResource
  sku: {
    name: sku.name
    tier: sku.tier
    capacity: sku.capacity
  }
  properties: {
    zoneRedundant: false
    requestedBackupStorageRedundancy: requestedBackupStorageRedundancy
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: int(maxSizeBytes)
  }
}
