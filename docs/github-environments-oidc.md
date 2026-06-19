# GitHub Environments y Azure OIDC

## Objetivo

Configurar GitHub como unico motor CI/CD para Cero Huella IA, usando GitHub Environments y autenticacion OIDC hacia Azure.

## Environments requeridos

| Environment | Uso | Aprobacion |
| --- | --- | --- |
| `dev` | Despliegue automatico desde `develop`. | No requerida. |
| `qa` | Despliegue desde `main` despues del PR `develop -> main`. | Requerida. |
| `prod` | Promocion final productiva pendiente. | Requerida antes de usarlo. |

## Plugin GitHub

En esta sesion se usa el plugin `@github` para operaciones GitHub. El plugin permite trabajar con repositorio, PRs y GitHub Actions, pero no expone una herramienta para crear environments ni administrar secrets de Actions.

Por ello se agrega el script:

```text
infra/github/configure-environments.ps1
```

El script usa la API REST de GitHub y requiere:

```powershell
$env:GITHUB_TOKEN = "<token-con-admin-del-repo>"
```

Ejemplo sin reviewers:

```powershell
.\infra\github\configure-environments.ps1
```

Ejemplo con aprobadores por ID de usuario:

```powershell
.\infra\github\configure-environments.ps1 `
  -QaReviewerUserIds 123456 `
  -ProdReviewerUserIds 123456
```

Los IDs de usuario/equipo deben obtenerse desde GitHub API o administracion de la organizacion.

## Azure OIDC

Para evitar secretos largos de Azure, GitHub Actions debe autenticarse con OIDC.

Script:

```text
infra/azure/create-github-oidc-app.ps1
```

Ejemplo:

```powershell
az login
az account set --subscription "<subscription-id>"

.\infra\azure\create-github-oidc-app.ps1 `
  -RoleScope "/subscriptions/<subscription-id>" `
  -AssignUserAccessAdministrator
```

`Contributor` permite crear recursos. `User Access Administrator` se requiere si Terraform creara asignaciones RBAC, por ejemplo `AcrPull` para managed identities.

## Variables por environment

Configurar como GitHub Environment variables o secrets:

| Nombre | Tipo | Comentario |
| --- | --- | --- |
| `AZURE_CLIENT_ID` | variable/secret | Devuelto por el script OIDC. |
| `AZURE_TENANT_ID` | variable/secret | Devuelto por el script OIDC. |
| `AZURE_SUBSCRIPTION_ID` | variable/secret | Devuelto por el script OIDC. |
| `GOOGLE_CLOUD_PROJECT_ID` | secret | ID de proyecto Google Cloud DLP. |
| `GOOGLE_APPLICATION_CREDENTIALS_B64` | secret | JSON de service account en Base64. |
| `POSTGRES_ADMIN_PASSWORD` | secret | Password por ambiente. |
| `TFSTATE_RESOURCE_GROUP_NAME` | variable | Resource group del backend Terraform. |
| `TFSTATE_STORAGE_ACCOUNT_NAME` | variable | Storage account del backend Terraform. |
| `TFSTATE_CONTAINER_NAME` | variable | Container del backend Terraform, normalmente `tfstate`. |
| `ACR_ID` | variable | ID del ACR compartido. No aplica para `shared`. |
| `ACR_LOGIN_SERVER` | variable | Login server del ACR compartido. Requerido por Terraform y CD. |

`DATABASE_URL` no debe configurarse manualmente si Terraform lo compone y lo guarda como secret de Container App.

## Workflow CD

El workflow `.github/workflows/deploy.yml` usa los environments de GitHub como compuertas:

- `develop` despliega automaticamente a `dev`.
- Pull request `develop -> main` ejecuta validaciones antes de promover.
- `main` despliega a `qa` con aprobacion del environment `qa`.
- `workflow_dispatch` permite desplegar manualmente a `dev`, `qa` o `prod`; `prod` queda reservado para la siguiente etapa.

Cada despliegue:

1. Autentica contra Azure con OIDC.
2. Construye la imagen Docker con tag de SHA corto.
3. Publica la imagen en ACR.
4. Actualiza Azure Container App.
5. Ejecuta smoke test contra `/health`.
6. Publica imagen y URL en el resumen del workflow.

`prod` no se ejecuta automaticamente desde `main` en esta etapa.

## Reglas de seguridad

- No guardar secretos reales en archivos `*.tfvars`.
- No usar `GOOGLE_APPLICATION_CREDENTIALS_JSON`.
- No usar password de ACR; usar managed identity con `AcrPull`.
- En `qa` y `prod`, exigir aprobacion del environment.
- Tratar el backend Terraform como sensible.
