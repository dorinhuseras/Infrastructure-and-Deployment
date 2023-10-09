param keyVaultName string
param secretName string
param cosmosName string
param resourceRg string
param resourceSubId string

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-03-15' existing = {
	name: cosmosName
  scope: resourceGroup(resourceSubId, resourceRg)
}

resource kv 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: kv
  name: secretName
  properties: { 
    value: 'DefaultEndpointsProtocol=https;AccountName=${cosmosDbAccount.name};AccountKey=${cosmosDbAccount.listKeys().primaryMasterKey};TableEndpoint=https://${cosmosDbAccount.name}.table.cosmos.azure.com:443/;' 
  }
}
