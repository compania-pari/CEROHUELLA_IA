# Recrear despliegue Azure - CeroHuella IA

Esta guia resume como recrear la infraestructura Azure del proyecto sin incluir secretos.

## Recursos objetivo

- Resource group: `rg-cerohuella-dev`
- Azure PostgreSQL Flexible Server: `cerohuella-bd`
- Azure Container Registry: `acrcerohuella`
- Log Analytics Workspace: `workspacergcerohuelladevb248`
- Container Apps Environment: `managedEnvironment-rgcerohuelladev-8ac8`
- Azure Container App: `ca-cerohuella-api-dev`
- Imagen: `acrcerohuella.azurecr.io/cerohuella-ia`
- Puerto de la API: `8000`

## Scripts

Los scripts estan en:

```text
infra/azure
```

Orden recomendado:

1. `create-resources.ps1`
2. `configure-containerapp.ps1`
3. `create-devops-service-connection.ps1`
4. `create-devops-release.ps1`

## Variables y secretos necesarios

Los scripts no guardan secretos. Se deben pasar por parametros o variables de entorno.

Requeridos para la API:

- `DATABASE_URL`
- `GOOGLE_CLOUD_PROJECT_ID`
- `GOOGLE_APPLICATION_CREDENTIALS_B64`
- `GOOGLE_APPLICATION_CREDENTIALS_PATH`
- `STORAGE_ROOT`
- `MAX_FILE_SIZE_MB`
- `MAX_BATCH_FILES`

Para generar `GOOGLE_APPLICATION_CREDENTIALS_B64` desde PowerShell:

```powershell
$credentialsPath = "D:\sw\google-cloud\luis-prueba2_dlp.json"
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes($credentialsPath))
```

## Recreacion de BD

Despues de crear PostgreSQL y configurar `DATABASE_URL`, ejecutar migraciones:

```powershell
alembic upgrade head
```

## CI/CD

El build esta versionado en:

```text
.azuredevops/pipelines/build.yml
```

El Release clasico no esta versionado como YAML. Para recrearlo usar:

```text
infra/azure/create-devops-release.ps1
```

## Restaurar servicio apagado

Si se detuvo PostgreSQL:

```powershell
az postgres flexible-server start `
  --name cerohuella-bd `
  --resource-group rg-cerohuella-dev
```

Si se desactivo la revision de Container App, ejecutar un nuevo despliegue desde Release o actualizar la imagen:

```powershell
az containerapp update `
  --name ca-cerohuella-api-dev `
  --resource-group rg-cerohuella-dev `
  --image acrcerohuella.azurecr.io/cerohuella-ia:latest
```

## Cuidados

- No registrar valores reales de `DATABASE_URL`, JSON de Google, Service Principal ni passwords.
- Si se borra ACR, las imagenes se pierden y deben regenerarse con el pipeline.
- Si se borra PostgreSQL, se pierde la trazabilidad salvo que exista backup.
