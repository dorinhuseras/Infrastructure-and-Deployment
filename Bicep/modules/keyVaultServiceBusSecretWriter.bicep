param serviceBusName string 
param secretName string
param keyVaultName string
param resourceRg string
param resourceSubId string

resource kv 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' existing = {
  name: serviceBusName
  scope: resourceGroup(resourceSubId, resourceRg)
}

resource key 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2022-10-01-preview' existing = {
  name: 'RootManageSharedAccessKey'
  parent: serviceBusNamespace
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: kv
  name: secretName
  properties: {
    value: key.listKeys().primaryConnectionString
  }
}
