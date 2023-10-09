param keyVaultName string
param secretName string
param redisCacheName string
param resourceRg string
param resourceSubId string

resource redisCache 'Microsoft.Cache/redis@2022-06-01' existing = {
  name: redisCacheName
  scope: resourceGroup(resourceSubId, resourceRg)
}

resource kv 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: kv
  name: secretName
  properties: {
    value: '${redisCache.name}.redis.cache.windows.net:6380,password=${redisCache.listKeys().primaryKey},ssl=True,abortConnect=False'
  }
}
