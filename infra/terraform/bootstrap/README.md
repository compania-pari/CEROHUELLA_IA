# Bootstrap del backend Terraform

Este directorio contiene el script para crear el backend remoto de Terraform en Azure Storage.

## Recursos creados

Por defecto:

| Recurso | Nombre |
| --- | --- |
| Resource group | `rg-cerohuella-tfstate` |
| Storage account | `stcerohuellatf<suffix>` |
| Blob container | `tfstate` |

El sufijo del storage account se calcula desde la suscripcion Azure para ayudar a cumplir la unicidad global del nombre.

## Requisitos

- Azure CLI instalado.
- Sesion iniciada con `az login`.
- Suscripcion correcta seleccionada con `az account set`.
- Permisos para crear resource groups y storage accounts.

Verificar sesion:

```powershell
az account show
```

## Ejecucion

Usar valores por defecto:

```powershell
.\infra\terraform\bootstrap\create-backend.ps1
```

Indicar nombre exacto del storage account:

```powershell
.\infra\terraform\bootstrap\create-backend.ps1 `
  -StorageAccountName "stcerohuellatfdev001"
```

Cambiar region:

```powershell
.\infra\terraform\bootstrap\create-backend.ps1 `
  -Location "eastus"
```

## Salida esperada

El script imprime un bloque `backend.hcl` de ejemplo. Copiar esos valores en los ambientes Terraform cuando se creen las carpetas `envs/dev`, `envs/qa` y `envs/prod`.

Ejemplo:

```hcl
resource_group_name  = "rg-cerohuella-tfstate"
storage_account_name = "stcerohuellatfxxxxxxxx"
container_name       = "tfstate"
key                  = "envs/dev/terraform.tfstate"
```

## Controles habilitados

- HTTPS obligatorio.
- TLS minimo 1.2.
- Acceso publico a blobs deshabilitado.
- Versionado de blobs habilitado.
- Retencion de borrado de blobs y contenedores por 30 dias.

