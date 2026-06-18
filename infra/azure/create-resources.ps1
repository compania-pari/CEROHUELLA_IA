param(
    [string]$ResourceGroup = "rg-cerohuella-dev",
    [string]$Location = "eastus",
    [string]$PostgresLocation = "brazilsouth",
    [string]$AcrName = "acrcerohuella",
    [string]$PostgresServerName = "cerohuella-bd",
    [string]$PostgresAdminUser = "lpari",
    [Parameter(Mandatory = $true)]
    [string]$PostgresAdminPassword,
    [string]$LogAnalyticsWorkspace = "workspacergcerohuelladevb248",
    [string]$ContainerAppsEnvironment = "managedEnvironment-rgcerohuelladev-8ac8"
)

$ErrorActionPreference = "Stop"

az group create `
    --name $ResourceGroup `
    --location $Location

az acr create `
    --resource-group $ResourceGroup `
    --name $AcrName `
    --sku Basic `
    --admin-enabled false

az monitor log-analytics workspace create `
    --resource-group $ResourceGroup `
    --workspace-name $LogAnalyticsWorkspace `
    --location $Location `
    --retention-time 30

az containerapp env create `
    --name $ContainerAppsEnvironment `
    --resource-group $ResourceGroup `
    --location $Location `
    --logs-workspace-id $(az monitor log-analytics workspace show --resource-group $ResourceGroup --workspace-name $LogAnalyticsWorkspace --query customerId -o tsv) `
    --logs-workspace-key $(az monitor log-analytics workspace get-shared-keys --resource-group $ResourceGroup --workspace-name $LogAnalyticsWorkspace --query primarySharedKey -o tsv)

az postgres flexible-server create `
    --resource-group $ResourceGroup `
    --name $PostgresServerName `
    --location $PostgresLocation `
    --admin-user $PostgresAdminUser `
    --admin-password $PostgresAdminPassword `
    --sku-name Standard_B1ms `
    --tier Burstable `
    --storage-size 32 `
    --version 18 `
    --public-access none

Write-Host "Recursos base creados. Revisar reglas de firewall PostgreSQL antes de conectar la API."
