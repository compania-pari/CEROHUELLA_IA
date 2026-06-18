param(
    [string]$ResourceGroup = "rg-cerohuella-dev",
    [string]$ContainerAppName = "ca-cerohuella-api-dev",
    [string]$EnvironmentName = "managedEnvironment-rgcerohuelladev-8ac8",
    [string]$AcrName = "acrcerohuella",
    [string]$Image = "acrcerohuella.azurecr.io/cerohuella-ia:latest",
    [Parameter(Mandatory = $true)]
    [string]$DatabaseUrl,
    [Parameter(Mandatory = $true)]
    [string]$GoogleCloudProjectId,
    [Parameter(Mandatory = $true)]
    [string]$GoogleApplicationCredentialsB64,
    [string]$GoogleApplicationCredentialsPath = "/tmp/google-application-credentials.json",
    [string]$StorageRoot = "storage",
    [int]$MaxFileSizeMb = 25,
    [int]$MaxBatchFiles = 10
)

$ErrorActionPreference = "Stop"

$acrLoginServer = az acr show `
    --name $AcrName `
    --resource-group $ResourceGroup `
    --query loginServer `
    -o tsv

az containerapp create `
    --name $ContainerAppName `
    --resource-group $ResourceGroup `
    --environment $EnvironmentName `
    --image $Image `
    --target-port 8000 `
    --ingress external `
    --registry-server $acrLoginServer `
    --min-replicas 0 `
    --max-replicas 1 `
    --cpu 0.5 `
    --memory 1Gi

az containerapp secret set `
    --name $ContainerAppName `
    --resource-group $ResourceGroup `
    --secrets `
        "database-url=$DatabaseUrl" `
        "google-application-credentials-b64=$GoogleApplicationCredentialsB64"

az containerapp update `
    --name $ContainerAppName `
    --resource-group $ResourceGroup `
    --set-env-vars `
        "APP_ENV=dev" `
        "DATABASE_URL=secretref:database-url" `
        "GOOGLE_CLOUD_PROJECT_ID=$GoogleCloudProjectId" `
        "GOOGLE_APPLICATION_CREDENTIALS_B64=secretref:google-application-credentials-b64" `
        "GOOGLE_APPLICATION_CREDENTIALS_PATH=$GoogleApplicationCredentialsPath" `
        "STORAGE_ROOT=$StorageRoot" `
        "MAX_FILE_SIZE_MB=$MaxFileSizeMb" `
        "MAX_BATCH_FILES=$MaxBatchFiles"

Write-Host "Container App configurada: $ContainerAppName"
