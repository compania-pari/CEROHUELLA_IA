param(
    [string]$ResourceGroupName = "rg-cerohuella-tfstate",
    [string]$Location = "eastus",
    [string]$StorageAccountName = "",
    [string]$ContainerName = "tfstate",
    [string]$Project = "cerohuella-ia",
    [string]$Owner = "lpari",
    [string]$CostCenter = "dmc",
    [int]$RetentionDays = 30
)

$ErrorActionPreference = "Stop"

function Test-AzureCli {
    $az = Get-Command az -ErrorAction SilentlyContinue
    if (-not $az) {
        throw "Azure CLI no esta disponible en PATH."
    }
}

function Get-SubscriptionId {
    $subscriptionId = az account show --query id -o tsv
    if (-not $subscriptionId) {
        throw "No hay una sesion Azure activa. Ejecuta 'az login' y selecciona la suscripcion correcta."
    }
    return $subscriptionId
}

function Get-DefaultStorageAccountName {
    param([string]$SubscriptionId)

    $normalized = ($SubscriptionId -replace "[^a-zA-Z0-9]", "").ToLowerInvariant()
    $suffix = $normalized.Substring(0, [Math]::Min(8, $normalized.Length))
    return "stcerohuellatf$suffix"
}

function Assert-StorageAccountName {
    param([string]$Name)

    if ($Name -notmatch "^[a-z0-9]{3,24}$") {
        throw "StorageAccountName debe tener entre 3 y 24 caracteres, solo minusculas y numeros. Valor: $Name"
    }
}

Test-AzureCli
$subscriptionId = Get-SubscriptionId

if ([string]::IsNullOrWhiteSpace($StorageAccountName)) {
    $StorageAccountName = Get-DefaultStorageAccountName -SubscriptionId $subscriptionId
}

$StorageAccountName = $StorageAccountName.ToLowerInvariant()
Assert-StorageAccountName -Name $StorageAccountName

$tags = @(
    "project=$Project",
    "environment=shared",
    "managedBy=terraform-bootstrap",
    "repository=compania-pari/CEROHUELLA_IA",
    "owner=$Owner",
    "costCenter=$CostCenter",
    "workload=terraform-state"
)

Write-Host "Creando resource group de estado Terraform: $ResourceGroupName"
az group create `
    --name $ResourceGroupName `
    --location $Location `
    --tags $tags `
    --only-show-errors `
    -o none

Write-Host "Creando storage account de estado Terraform: $StorageAccountName"
az storage account create `
    --name $StorageAccountName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --sku Standard_LRS `
    --kind StorageV2 `
    --min-tls-version TLS1_2 `
    --https-only true `
    --allow-blob-public-access false `
    --tags $tags `
    --only-show-errors `
    -o none

Write-Host "Habilitando versionado y retencion de borrado en blob service."
az storage account blob-service-properties update `
    --account-name $StorageAccountName `
    --resource-group $ResourceGroupName `
    --enable-versioning true `
    --enable-delete-retention true `
    --delete-retention-days $RetentionDays `
    --enable-container-delete-retention true `
    --container-delete-retention-days $RetentionDays `
    --only-show-errors `
    -o none

Write-Host "Creando container de estado Terraform: $ContainerName"
az storage container create `
    --name $ContainerName `
    --account-name $StorageAccountName `
    --auth-mode login `
    --only-show-errors `
    -o none

Write-Host ""
Write-Host "Backend Terraform listo."
Write-Host ""
Write-Host "Usar este backend.hcl como base por ambiente:"
Write-Host ""
Write-Host "resource_group_name  = `"$ResourceGroupName`""
Write-Host "storage_account_name = `"$StorageAccountName`""
Write-Host "container_name       = `"$ContainerName`""
Write-Host "key                  = `"envs/dev/terraform.tfstate`""

