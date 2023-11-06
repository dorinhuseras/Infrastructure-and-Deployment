param location string 
param sku string = 'VpnGw1'
param projectName string
param resourceTags object
param subnetId string
param vpnaddressPrefixes array = ['172.16.201.0/24']
param vpnClientProtocols array =  ['OpenVPN']
param vpnAuthenticationTypes array = ['AAD']
param aadaudience string = '41b23e61-6c1e-4545-b367-cd054e0ed4b4'
param tenantId string = '754b003a-1dfd-46c5-8fe3-f983017ae300'
param aadissuer string = 'https://sts.windows.net/${tenantId}/'
param aadTenant string = 'https://login.microsoftonline.com/${tenantId}'
param vpnGatewayGeneration string = 'Generation1'
param vpnType string = 'RouteBased'


resource publicIpResource 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
	name: '${projectName}Public-ip'
    location: location
    tags: resourceTags
    sku: {
	name: 'Standard'
    tier: 'Regional'
    }
    properties: {
	    publicIPAddressVersion: 'IPv4'
        publicIPAllocationMethod: 'Static'
        idleTimeoutInMinutes: 4
    }
}


resource virtualNetworkGateway 'Microsoft.Network/virtualNetworkGateways@2022-05-01' = {
  name: projectName
  location: location
  tags: resourceTags
  properties: {
    activeActive: false
    bgpSettings: {
      asn: 65515
      peerWeight: 0
    }
    customRoutes: {
      addressPrefixes: []
    }
    disableIPSecReplayProtection: false
    enableBgp: false
    enableBgpRouteTranslationForNat: false
    enablePrivateIpAddress: false
    gatewayType: 'Vpn'
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpResource.id
          }
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    natRules: []
    sku: {
      name: sku
      tier: sku
    }
    vpnClientConfiguration: {
      aadAudience: aadaudience
      aadIssuer: aadissuer
      aadTenant: aadTenant
      vpnAuthenticationTypes: vpnAuthenticationTypes
      vpnClientAddressPool: {
        addressPrefixes: vpnaddressPrefixes
      }
      vpnClientIpsecPolicies: []
      vpnClientProtocols: vpnClientProtocols
      vpnClientRevokedCertificates: []
      vpnClientRootCertificates: []
    }
    vpnGatewayGeneration: vpnGatewayGeneration
    vpnType: vpnType
  }
}