targetScope = 'resourceGroup'

@allowed(['dev', 'prod'])
param env string = 'dev'

// Definim cele două regiuni "salvatoare"
var locPoland = 'polandcentral'
var locGermany = 'germanywestcentral'

@secure()
param sqlPassword string

var uniqueId = uniqueString(resourceGroup().id)

// 1. NETWORK (Polonia)
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: 'vnet-logistics-${env}'
  location: locPoland
  properties: {
    addressSpace: { addressPrefixes: ['10.0.0.0/16'] }
    subnets: [{ name: 'snet-backend', properties: { addressPrefix: '10.0.1.0/24' } }]
  }
}

// 2. STORAGE (Polonia)
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: take('stlog${env}${uniqueId}', 24)
  location: locPoland
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true
    publicNetworkAccess: 'Disabled'
  }
}

// 3. SQL SERVER (Polonia)
resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: 'sql-log-${env}-${uniqueId}'
  location: locPoland
  properties: {
    administratorLogin: 'adminDevOps'
    administratorLoginPassword: sqlPassword
    publicNetworkAccess: 'Disabled'
  }
}

// 4. IOT HUB (Germania - singura unde merge)
resource iotHub 'Microsoft.Devices/IotHubs@2023-06-30' = {
  name: 'iot-fleet-hub-${env}'
  location: locGermany
  sku: { name: 'S1', capacity: 1 }
}

// 5. PLAN & FUNCTION (Germania - necesar pentru Python)
resource serverlessPlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: 'plan-log-${env}'
  location: locGermany
  kind: 'linux' 
  sku: { 
    name: 'Y1' 
    tier: 'Dynamic' 
  }
  properties: {
    reserved: true // <--- MUTATĂ AICI ÎN PROPERTIES
  }
}

resource azureFunction 'Microsoft.Web/sites@2023-01-01' = {
  name: 'func-log-py-${env}-${uniqueId}'
  location: locGermany
  kind: 'functionapp'
  identity: { type: 'SystemAssigned' }
  properties: { 
    serverFarmId: serverlessPlan.id
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.9'
    }
  }
}
