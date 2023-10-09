param keyVaultName string
param secretName string
param sqlDatabaseName string
param sqlServerName string
param resourceRg string
param resourceSubId string
param useUamiConnection bool


resource sqlServerResource 'Microsoft.Sql/servers@2022-05-01-preview' existing = {
  name: sqlServerName
  scope: resourceGroup(resourceSubId, resourceRg)
}

resource sqlDatabase  'Microsoft.Sql/servers/databases@2022-05-01-preview' existing = {
  name: sqlDatabaseName
  parent: sqlServerResource
}

resource kv 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource miSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = if (useUamiConnection) {
  dependsOn: [sqlDatabase]
  parent: kv
  name: secretName
  properties: {
#disable-next-line no-hardcoded-env-urls
    value: 'Server=tcp:${sqlServerResource.name}.database.windows.net;Initial Catalog=${sqlDatabase.name};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;' 
  }
}
