param(
    [string]$Organization = "https://dev.azure.com/lparitOrg",
    [string]$ReleaseOrganization = "https://vsrm.dev.azure.com/lparitOrg",
    [string]$Project = "cerohuella_ia",
    [int]$BuildDefinitionId = 2,
    [string]$BuildDefinitionName = "build_cerohuella_ia",
    [string]$ReleaseName = "release_cerohuella_ia_dev",
    [string]$ArtifactAlias = "_build_cerohuella_ia",
    [string]$ServiceConnectionId = "31eb8fb4-0d1f-468d-a4be-068790aeaba7",
    [int]$QueueId = 19,
    [string]$ResourceGroup = "rg-cerohuella-dev",
    [string]$ContainerAppName = "ca-cerohuella-api-dev"
)

$ErrorActionPreference = "Stop"

$projectInfo = az devops project show `
    --organization $Organization `
    --project $Project `
    -o json | ConvertFrom-Json

$inlineScript = @"
`$ErrorActionPreference = "Stop"
`$metadataPath = "`$(System.DefaultWorkingDirectory)\$ArtifactAlias\drop\image.env"

if (-not (Test-Path -LiteralPath `$metadataPath)) {
    throw "No se encontro image.env en: `$metadataPath"
}

`$metadata = @{}
Get-Content -LiteralPath `$metadataPath | ForEach-Object {
    if (`$_ -match "^([^=]+)=(.*)`$") {
        `$metadata[`$matches[1]] = `$matches[2]
    }
}

`$image = `$metadata["IMAGE_FULL_NAME"]
if ([string]::IsNullOrWhiteSpace(`$image)) {
    throw "IMAGE_FULL_NAME no esta definido en image.env"
}

Write-Host "Desplegando imagen: `$image"
az containerapp update `
  --name "$ContainerAppName" `
  --resource-group "$ResourceGroup" `
  --image "`$image"
"@

$definition = [ordered]@{
    name = $ReleaseName
    path = "\"
    releaseNameFormat = "release-cerohuella-ia-`$(rev:r)"
    description = "Despliega automaticamente la imagen Docker generada por $BuildDefinitionName hacia Azure Container App dev."
    variables = @{}
    variableGroups = @()
    artifacts = @(
        [ordered]@{
            alias = $ArtifactAlias
            type = "Build"
            definitionReference = [ordered]@{
                definition = [ordered]@{ id = "$BuildDefinitionId"; name = $BuildDefinitionName }
                project = [ordered]@{ id = $projectInfo.id; name = $Project }
                defaultVersionType = [ordered]@{ id = "latestType"; name = "Latest" }
                defaultVersionBranch = [ordered]@{ id = "refs/heads/main"; name = "main" }
                artifactSourceDefinitionUrl = [ordered]@{ id = "https://dev.azure.com/lparitOrg/_permalink/_build/index?definitionId=$BuildDefinitionId"; name = "" }
                IsMultiDefinitionType = [ordered]@{ id = "False"; name = "False" }
                defaultVersionSpecific = [ordered]@{ id = ""; name = "" }
                defaultVersionTags = [ordered]@{ id = ""; name = "" }
                definitions = [ordered]@{ id = ""; name = "" }
                repository = [ordered]@{ id = ""; name = "" }
            }
            isPrimary = $true
            isRetained = $false
        }
    )
    triggers = @(
        [ordered]@{
            artifactAlias = $ArtifactAlias
            triggerConditions = @()
            triggerType = "artifactSource"
        }
    )
    environments = @(
        [ordered]@{
            name = "Dev"
            rank = 1
            variables = @{}
            variableGroups = @()
            preDeployApprovals = [ordered]@{ approvals = @([ordered]@{ rank = 1; isAutomated = $true; isNotificationOn = $false }) }
            postDeployApprovals = [ordered]@{ approvals = @([ordered]@{ rank = 1; isAutomated = $true; isNotificationOn = $false }) }
            deployPhases = @(
                [ordered]@{
                    phaseType = "agentBasedDeployment"
                    name = "Agent job"
                    rank = 1
                    deploymentInput = [ordered]@{
                        parallelExecution = [ordered]@{ parallelExecutionType = "none" }
                        agentSpecification = [ordered]@{ identifier = "windows-2022" }
                        skipArtifactsDownload = $false
                        artifactsDownloadInput = [ordered]@{ downloadInputs = @() }
                        queueId = $QueueId
                        demands = @()
                        enableAccessToken = $false
                        timeoutInMinutes = 0
                        jobCancelTimeoutInMinutes = 1
                        condition = "succeeded()"
                        overrideInputs = @{}
                    }
                    workflowTasks = @(
                        [ordered]@{
                            taskId = "46e4be58-730b-4389-8a2f-ea10b3e5e815"
                            version = "2.*"
                            name = "Desplegar imagen en Azure Container App"
                            refName = ""
                            enabled = $true
                            alwaysRun = $false
                            continueOnError = $false
                            timeoutInMinutes = 0
                            definitionType = "task"
                            overrideInputs = @{}
                            condition = "succeeded()"
                            inputs = [ordered]@{
                                connectedServiceNameARM = $ServiceConnectionId
                                scriptType = "ps"
                                scriptLocation = "inlineScript"
                                inlineScript = $inlineScript
                                arguments = ""
                                powerShellErrorActionPreference = "stop"
                                addSpnToEnvironment = "false"
                                useGlobalConfig = "false"
                                cwd = ""
                                failOnStandardError = "false"
                            }
                        }
                    )
                }
            )
            conditions = @([ordered]@{ conditionType = "event"; name = "ReleaseStarted"; value = ""; result = $null })
            executionPolicy = [ordered]@{ concurrencyCount = 1; queueDepthCount = 0 }
            retentionPolicy = [ordered]@{ daysToKeep = 30; releasesToKeep = 3; retainBuild = $true }
        }
    )
    properties = @{}
}

$payloadPath = Join-Path $env:TEMP "cerohuella-release-definition.json"
$json = $definition | ConvertTo-Json -Depth 100
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($payloadPath, $json, $utf8NoBom)

az devops invoke `
    --org $ReleaseOrganization `
    --area release `
    --resource definitions `
    --route-parameters project=$Project `
    --api-version 7.1 `
    --http-method POST `
    --in-file $payloadPath
