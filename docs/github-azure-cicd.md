# CI/CD GitHub + Azure - Cero Huella IA

## Objetivo

Usar GitHub Actions como unico motor CI/CD para Cero Huella IA, desplegando en Azure Container Apps con promocion controlada desde `develop` hacia `main`. En esta etapa el alcance operativo llega hasta `qa`; `prod` queda manual y pendiente para una siguiente etapa.

## Ramas

| Rama | Proposito | Despliegue |
| --- | --- | --- |
| `develop` | Integracion tecnica | Automatico a `dev`. |
| `main` | Rama estable | Automatico a `qa` despues del merge aprobado desde `develop`. |

## Workflows

| Workflow | Archivo | Uso |
| --- | --- | --- |
| CI | `.github/workflows/ci.yml` | Pruebas, build Docker, Trivy y `pip-audit`. |
| Terraform | `.github/workflows/terraform.yml` | `fmt`, `validate`, `plan` y `apply` por environment. |
| CD | `.github/workflows/deploy.yml` | Build/push a ACR y despliegue a Container Apps. |

## CI

Se ejecuta en pull request y push hacia `develop` o `main`. El pull request de promocion esperado es de `develop` hacia `main`.

Pasos principales:

1. Checkout.
2. Python 3.12.
3. `python -m pip install -e .[dev]`.
4. Import de `app.main`.
5. `pytest --junitxml=pytest-results.xml`.
6. `pip-audit` no bloqueante con artifact JSON.
7. Build Docker.
8. Trivy no bloqueante con artifact JSON.

## CD

### `develop` a `dev`

```text
push develop
 -> build imagen con tag SHA corto
 -> push a ACR
 -> az containerapp update en dev
 -> smoke test /health
```

### `develop` a `main`, y `main` a `qa`

```text
PR develop -> main
 -> CI
 -> aprobacion/merge
push main
 -> aprobacion environment qa
 -> build imagen con tag SHA corto
 -> push a ACR
 -> despliegue qa
 -> smoke test /health
```

`prod` no se ejecuta automaticamente desde `main` en esta etapa. El workflow conserva una entrada manual `workflow_dispatch` para `prod`, pero no debe usarse hasta que se confirme la infraestructura productiva.

## Variables GitHub

Configurar en GitHub Environments `dev`, `qa` y `prod`:

| Nombre | Tipo | Uso |
| --- | --- | --- |
| `AZURE_CLIENT_ID` | Variable | OIDC con Azure. |
| `AZURE_TENANT_ID` | Variable | OIDC con Azure. |
| `AZURE_SUBSCRIPTION_ID` | Variable | OIDC con Azure. |
| `ACR_LOGIN_SERVER` | Variable | Build/push de imagen Docker. |
| `ACR_ID` | Variable | Terraform asigna `AcrPull`. |
| `TFSTATE_RESOURCE_GROUP_NAME` | Variable | Backend Terraform. |
| `TFSTATE_STORAGE_ACCOUNT_NAME` | Variable | Backend Terraform. |
| `TFSTATE_CONTAINER_NAME` | Variable | Backend Terraform. |
| `GOOGLE_CLOUD_PROJECT_ID` | Secret | Google DLP. |
| `GOOGLE_APPLICATION_CREDENTIALS_B64` | Secret | Credencial Google en Base64. |
| `POSTGRES_ADMIN_PASSWORD` | Secret | Password PostgreSQL por ambiente. |

## Rollback basico

1. Identificar imagen anterior en ACR.
2. Ejecutar manualmente:

```powershell
az containerapp update `
  --name ca-cerohuella-api-<env> `
  --resource-group rg-cerohuella-<env> `
  --image acrcerohuellashared.azurecr.io/cerohuella-ia:<tag-anterior>
```

3. Validar:

```powershell
$fqdn = az containerapp show `
  --name ca-cerohuella-api-<env> `
  --resource-group rg-cerohuella-<env> `
  --query properties.configuration.ingress.fqdn `
  --output tsv

curl.exe -f "https://$fqdn/health"
```

## Flujo oficial de trabajo

El repositorio destino es `compania-pari/CEROHUELLA_IA`.

```text
Trabajo diario en develop
 -> push a develop
 -> CI
 -> CD dev
 -> PR develop -> main
 -> CI de validacion
 -> merge a main
 -> CI
 -> CD qa con aprobacion del environment qa
```

No se considera una rama temporal remota como parte del flujo oficial. Si se crea una rama local de apoyo, debe integrarse a `develop` y eliminarse del remoto cuando termine.
