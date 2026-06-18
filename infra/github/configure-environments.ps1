param(
    [string]$Owner = "compania-pari",
    [string]$Repository = "CEROHUELLA_IA",
    [string[]]$Environments = @("dev", "qa", "prod"),
    [int[]]$QaReviewerUserIds = @(),
    [int[]]$ProdReviewerUserIds = @(),
    [int[]]$QaReviewerTeamIds = @(),
    [int[]]$ProdReviewerTeamIds = @(),
    [string]$Token = $env:GITHUB_TOKEN
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Token)) {
    throw "Define GITHUB_TOKEN con permisos de administracion del repositorio antes de ejecutar este script."
}

$headers = @{
    Accept                 = "application/vnd.github+json"
    Authorization          = "Bearer $Token"
    "X-GitHub-Api-Version" = "2022-11-28"
}

function New-ReviewerPayload {
    param(
        [int[]]$UserIds,
        [int[]]$TeamIds
    )

    $reviewers = @()
    foreach ($userId in $UserIds) {
        $reviewers += @{ type = "User"; id = $userId }
    }
    foreach ($teamId in $TeamIds) {
        $reviewers += @{ type = "Team"; id = $teamId }
    }
    return $reviewers
}

function Set-GitHubEnvironment {
    param(
        [string]$EnvironmentName,
        [array]$Reviewers
    )

    $uri = "https://api.github.com/repos/$Owner/$Repository/environments/$EnvironmentName"
    $body = @{
        deployment_branch_policy = $null
    }

    if ($Reviewers.Count -gt 0) {
        $body.wait_timer                = 0
        $body.reviewers                 = $Reviewers
        $body.prevent_self_review       = $true
        $body.can_admins_bypass         = $true
    }

    Write-Host "Configurando GitHub Environment: $EnvironmentName"
    Invoke-RestMethod `
        -Method Put `
        -Uri $uri `
        -Headers $headers `
        -Body ($body | ConvertTo-Json -Depth 10) `
        -ContentType "application/json" | Out-Null
}

foreach ($environment in $Environments) {
    switch ($environment) {
        "qa" {
            $reviewers = New-ReviewerPayload -UserIds $QaReviewerUserIds -TeamIds $QaReviewerTeamIds
            Set-GitHubEnvironment -EnvironmentName $environment -Reviewers $reviewers
        }
        "prod" {
            $reviewers = New-ReviewerPayload -UserIds $ProdReviewerUserIds -TeamIds $ProdReviewerTeamIds
            Set-GitHubEnvironment -EnvironmentName $environment -Reviewers $reviewers
        }
        default {
            Set-GitHubEnvironment -EnvironmentName $environment -Reviewers @()
        }
    }
}

Write-Host "GitHub Environments configurados. Configura secrets y variables desde GitHub UI o API segura."

