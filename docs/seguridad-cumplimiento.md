# Seguridad y cumplimiento - GitHub + Azure

## Objetivo

Definir controles minimos para el flujo GitHub Actions + Terraform + Azure de Cero Huella IA, sin publicar secretos ni ejecutar cambios destructivos desde el repositorio.

## Secretos

- `.env` esta ignorado por Git y no debe versionarse.
- Los archivos `*.tfvars` reales estan ignorados; solo se versionan `*.tfvars.example`.
- Las credenciales Google en Azure deben ir como `GOOGLE_APPLICATION_CREDENTIALS_B64`.
- No usar `GOOGLE_APPLICATION_CREDENTIALS_JSON` en Azure.
- No usar usuario/password de ACR; el runtime usa managed identity con `AcrPull`.
- GitHub Actions se autentica con Azure mediante OIDC, no con client secret.

## Terraform

- `postgres_admin_password` y `google_application_credentials_b64` son variables sensibles.
- `DATABASE_URL` se compone dentro de Terraform y se publica como secret de Container App.
- El backend remoto de Terraform debe tratarse como sensible.
- No ejecutar `terraform apply` sin revisar plan y environment correcto.

## CI/CD

- CI ejecuta pruebas, build Docker y Trivy.
- `pip-audit` queda habilitado inicialmente como no bloqueante y publica `security-reports/pip-audit.json`.
- Trivy queda no bloqueante al inicio para no frenar la adopcion; el reporte se publica como artifact.
- Los workflows no imprimen secretos ni exportan valores sensibles al resumen.

## HTTPS

Azure Container Apps expone la API publica con HTTPS administrado por Azure. No se configura ingreso HTTP plano como destino operativo.

## Riesgos residuales

| Riesgo | Estado | Mitigacion inicial |
| --- | --- | --- |
| Almacenamiento local de PDFs | Aceptado temporalmente | Mantener `STORAGE_ROOT` local y no versionar archivos procesados. Evaluar Azure Files en una fase posterior. |
| `min_replicas = 0` en dev/qa | Aceptado por costo | Usar smoke tests y alertas. En prod se define al menos una replica. |
| Costos de observabilidad | Aceptado | Retencion inicial baja y umbrales ajustables por ambiente. |
| Alertas sin canal definitivo | Pendiente | Action Group parametrizado; falta decidir correo, webhook, Teams u otro canal. |
| PostgreSQL privado | Controlado | Runner GitHub no accede directo; migraciones deben ejecutarse desde Azure. |
| Escaneos no bloqueantes | Deuda controlada | Revisar reportes y decidir severidades bloqueantes cuando el pipeline este estabilizado. |

## Revision local

Comandos utiles antes de publicar:

```powershell
git status --short
git diff --check
git grep -n "BEGIN PRIVATE KEY\|AZURE_CLIENT_SECRET\|AWS_SECRET_ACCESS_KEY"
pytest
terraform fmt -check -recursive infra\terraform
```

