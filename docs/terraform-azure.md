# Terraform Azure - Guia operativa

## Objetivo

Provisionar infraestructura nueva para Cero Huella IA en Azure usando Terraform, con ambientes `shared`, `dev`, `qa` y `prod`.

## Orden de ejecucion

1. Crear backend remoto.
2. Aplicar `shared`.
3. Obtener outputs de ACR.
4. Completar variables reales de `dev`, `qa` y `prod`.
5. Ejecutar `plan`.
6. Revisar plan.
7. Ejecutar `apply` por ambiente.

## Bootstrap del backend

```powershell
.\infra\terraform\bootstrap\create-backend.ps1
```

El script crea:

- Resource group `rg-cerohuella-tfstate`.
- Storage Account para estado.
- Container `tfstate`.
- Versionado y retencion de borrado.

No contiene secretos y no debe ejecutarse sin confirmar parametros.

## Aplicar `shared`

```powershell
cd infra\terraform\envs\shared
Copy-Item backend.hcl.example backend.hcl
Copy-Item shared.tfvars.example shared.tfvars

terraform init -backend-config=backend.hcl
terraform validate
terraform plan -var-file=shared.tfvars -out=tfplan
terraform apply tfplan
terraform output
```

Usar los outputs:

- `acr_id`
- `acr_login_server`

para completar `dev.tfvars`, `qa.tfvars` y `prod.tfvars`.

## Plan/apply por ambiente

Ejemplo `dev`:

```powershell
cd infra\terraform\envs\dev
Copy-Item backend.hcl.example backend.hcl
Copy-Item dev.tfvars.example dev.tfvars

terraform init -backend-config=backend.hcl
terraform fmt
terraform validate
terraform plan -var-file=dev.tfvars -out=tfplan
terraform apply tfplan
```

Repetir el mismo patron en `qa` y `prod` con su archivo `*.tfvars`.

## GitHub Actions

El workflow `.github/workflows/terraform.yml` permite:

- `fmt` y `validate` en PR/push.
- `plan` manual por environment.
- `apply` manual por environment.

Para `apply`, usar GitHub Environments y aprobaciones, especialmente en `qa` y `prod`.

## Variables sensibles

No versionar valores reales:

- `postgres_admin_password`
- `google_application_credentials_b64`
- `DATABASE_URL`
- `*.tfvars`
- `backend.hcl`

Terraform marca como sensibles las variables de password y credenciales Google. El estado remoto debe tratarse como sensible.

## Limpieza de recursos

Para controlar costos, destruir primero ambientes no productivos:

```powershell
cd infra\terraform\envs\dev
terraform plan -destroy -var-file=dev.tfvars -out=destroy.tfplan
terraform apply destroy.tfplan
```

No destruir `shared` si aun existen ambientes que usan el ACR compartido.

## Validacion

```powershell
terraform fmt -check -recursive infra\terraform
terraform -chdir=infra\terraform\envs\shared init -backend=false
terraform -chdir=infra\terraform\envs\shared validate
terraform -chdir=infra\terraform\envs\dev init -backend=false
terraform -chdir=infra\terraform\envs\dev validate
terraform -chdir=infra\terraform\envs\qa init -backend=false
terraform -chdir=infra\terraform\envs\qa validate
terraform -chdir=infra\terraform\envs\prod init -backend=false
terraform -chdir=infra\terraform\envs\prod validate
```

