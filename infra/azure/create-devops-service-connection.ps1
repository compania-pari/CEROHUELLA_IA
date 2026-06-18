param(
    [string]$Organization = "https://dev.azure.com/lparitOrg",
    [string]$Project = "cerohuella_ia",
    [string]$SubscriptionId = "1043272f-49a4-48b9-8a42-18a70413117f",
    [string]$TenantId = "5b442477-bddd-408a-8b7e-356c9065832e",
    [string]$ServiceConnectionName = "sc-azure-cerohuella",
    [string]$ServicePrincipalName = "sp-cerohuella-devops"
)

$ErrorActionPreference = "Stop"

Write-Warning "Este script crea un Service Principal. No imprimir ni commitear el password generado."

$sp = az ad sp create-for-rbac `
    --name $ServicePrincipalName `
    --role Contributor `
    --scopes "/subscriptions/$SubscriptionId" `
    -o json | ConvertFrom-Json

$endpointFile = Join-Path $env:TEMP "cerohuella-azdo-service-connection.json"
$endpoint = @{
    data = @{
        subscriptionId = $SubscriptionId
        subscriptionName = "Azure subscription 1"
        environment = "AzureCloud"
        scopeLevel = "Subscription"
        creationMode = "Manual"
    }
    name = $ServiceConnectionName
    type = "azurerm"
    url = "https://management.azure.com/"
    authorization = @{
        scheme = "ServicePrincipal"
        parameters = @{
            tenantid = $TenantId
            serviceprincipalid = $sp.appId
            serviceprincipalkey = $sp.password
            authenticationType = "spnKey"
        }
    }
    isShared = $false
    isReady = $true
} | ConvertTo-Json -Depth 20

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($endpointFile, $endpoint, $utf8NoBom)

$created = az devops service-endpoint create `
    --organization $Organization `
    --project $Project `
    --service-endpoint-configuration $endpointFile `
    -o json | ConvertFrom-Json

az devops service-endpoint update `
    --organization $Organization `
    --project $Project `
    --id $created.id `
    --enable-for-all true `
    --output none

Write-Host "Service connection creada: $ServiceConnectionName"
Write-Host "Endpoint ID: $($created.id)"
