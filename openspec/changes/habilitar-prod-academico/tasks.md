## 1. Terraform PROD academico

- [x] 1.1 Ajustar `infra/terraform/envs/prod` para reutilizar un Container Apps Environment existente por defecto.
- [x] 1.2 Agregar VNet peering y Private DNS link para que PROD acceda a PostgreSQL privado desde el CAE compartido.
- [x] 1.3 Reducir compute de PROD a valores academicos: `0.5` CPU, `1Gi`, `min_replicas = 0`, `max_replicas = 1`.
- [x] 1.4 Actualizar `prod.tfvars.example` con variables de reutilizacion de CAE y valores minimos.

## 2. Documentacion y trazabilidad

- [x] 2.1 Actualizar documentacion de arquitectura, CI/CD y environments para reflejar PROD academico manual.
- [x] 2.2 Actualizar `tareas.md` y `AGENTS.md` con la decision y lecciones aprendidas.

## 3. Validacion local

- [x] 3.1 Ejecutar `terraform fmt` y `terraform validate` para `prod`.
- [x] 3.2 Ejecutar pruebas de aplicacion.
  - Nota: `pytest` fallo localmente por permisos de temporales, pero paso en GitHub Actions CI.
- [x] 3.3 Validar OpenSpec para `habilitar-prod-academico`.

## 4. Publicacion y despliegue

- [x] 4.1 Commit y push de los cambios a GitHub.
- [ ] 4.2 Ejecutar plan/apply de Terraform para `prod` usando GitHub Actions o Azure CLI.
  - Bloqueado: el environment `prod` no tiene secrets `GOOGLE_CLOUD_PROJECT_ID`, `GOOGLE_APPLICATION_CREDENTIALS_B64` ni `POSTGRES_ADMIN_PASSWORD`; no se cargaron valores falsos.
- [ ] 4.3 Ejecutar CD manual hacia `prod`.
- [ ] 4.4 Validar `/health` y observabilidad de `prod`.
