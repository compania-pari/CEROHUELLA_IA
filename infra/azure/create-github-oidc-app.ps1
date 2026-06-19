param(
    [string]$AppDisplayName = "sp-github-cerohuella-ia",
    [string]$GitHubOwner = "compania-pari",
    [string]$GitHubRepository = "CEROHUELLA_IA",
    [string[]]$Environments = @("dev", "qa", "prod"),
    [string]$RoleScope = "",
    [string]$RoleDefinitionName = "Contributor",
    [switch]$AssignUserAccessAdministrator
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw "Azure CLI no esta disponible en PATH."
}

$subscriptionId = az account show --query id -o tsv
$tenantId = az account show --query tenantId -o tsv

if (-not $subscriptionId -or -not $tenantId) {
    throw "No hay sesion Azure activa. Ejecuta 'az login' y selecciona la suscripcion correcta."
}

if ([string]::IsNullOrWhiteSpace($RoleScope)) {
    $RoleScope = "/subscriptions/$subscriptionId"
}

Write-Host "Creando app registration: $AppDisplayName"
$app = az ad app create --display-name $AppDisplayName | ConvertFrom-Json
$appId = $app.appId
$objectId = $app.id

Write-Host "Creando service principal."
az ad sp create --id $appId -o none

foreach ($environment in $Environments) {
    $credential = @{
        name        = "github-$environment"
        issuer      = "https://token.actions.githubusercontent.com"
        subject     = "repo:$GitHubOwner/$($GitHubRepository):environment:$environment"
        description = "GitHub Actions OIDC for $GitHubOwner/$GitHubRepository environment $environment"
        audiences   = @("api://AzureADTokenExchange")
    }

    $tempFile = New-TemporaryFile
    try {
        $credential | ConvertTo-Json -Depth 10 | Set-Content -Path $tempFile.FullName -Encoding utf8
        Write-Host "Creando credencial federada para environment: $environment"
        az ad app federated-credential create `
            --id $objectId `
            --parameters $tempFile.FullName `
            -o none
    }
    finally {
        Remove-Item -LiteralPath $tempFile.FullName -Force
    }
}

Write-Host "Asignando rol $RoleDefinitionName en $RoleScope"
az role assignment create `
    --assignee $appId `
    --role $RoleDefinitionName `
    --scope $RoleScope `
    -o none

if ($AssignUserAccessAdministrator) {
    Write-Host "Asignando rol User Access Administrator en $RoleScope"
    az role assignment create `
        --assignee $appId `
        --role "User Access Administrator" `
        --scope $RoleScope `
        -o none
}

Write-Host ""
Write-Host "Configurar estos valores en GitHub Environments:"
Write-Host "AZURE_CLIENT_ID=$appId"
Write-Host "AZURE_TENANT_ID=$tenantId"
Write-Host "AZURE_SUBSCRIPTION_ID=$subscriptionId"

