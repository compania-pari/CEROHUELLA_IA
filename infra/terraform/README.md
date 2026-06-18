# Terraform - Cero Huella IA

Infraestructura como codigo para desplegar Cero Huella IA en Azure con tres ambientes: `dev`, `qa` y `prod`.

## Estructura prevista

```text
infra/terraform/
  bootstrap/
    create-backend.ps1
    README.md
  modules/
  envs/
    dev/
    qa/
    prod/
```

## Backend remoto

El estado de Terraform debe guardarse en Azure Storage. Antes de ejecutar `terraform init` en cualquier ambiente, crear el backend remoto con:

```powershell
.\infra\terraform\bootstrap\create-backend.ps1
```

El script crea:

- Resource group de estado.
- Storage account.
- Blob container `tfstate`.
- Versionado de blobs.
- Retencion de borrado para blobs y contenedores.

No ejecutar el script sin confirmar sus parametros, porque crea recursos reales en Azure.

## Ambientes

Cada ambiente usara un archivo de estado separado:

| Ambiente | State key |
| --- | --- |
| `dev` | `envs/dev/terraform.tfstate` |
| `qa` | `envs/qa/terraform.tfstate` |
| `prod` | `envs/prod/terraform.tfstate` |

## Comandos base

Ejemplo para `dev` cuando exista la carpeta del ambiente:

```powershell
cd infra\terraform\envs\dev
terraform init -backend-config=backend.hcl
terraform fmt -recursive
terraform validate
terraform plan -var-file=dev.tfvars
```

## Seguridad

- No guardar secretos reales en archivos `*.tfvars` versionados.
- Usar `*.tfvars.example` para documentar variables.
- Usar GitHub Environments para secretos del pipeline.
- Tratar el estado remoto como informacion sensible.
- No ejecutar `terraform apply` desde una estacion local sin aprobacion explicita.

