# Tareas - Migracion CI/CD GitHub + Azure + Terraform

## Objetivo general

Llevar Cero Huella IA a un flujo CI/CD basado en GitHub Actions, provisionar infraestructura nueva en Azure con Terraform y habilitar observabilidad basica con servicios nativos de Azure. GitHub quedara como unico motor CI/CD activo. Azure proveera runtime, base de datos, registry y observabilidad.

## Decisiones confirmadas

- [x] Crear infraestructura nueva con Terraform.
- [x] Replicar flujo de clase `dev -> qa -> prod`.
- [x] Mantener almacenamiento local en disco para esta etapa.
- [x] Crear nueva instancia PostgreSQL desde Terraform.
- [x] Mantener GitHub como unico CI/CD.
- [x] Usar el plugin `@github` y Azure CLI (`az`) como herramientas operativas.
- [x] Repositorio GitHub destino: `compania-pari/CEROHUELLA_IA`.

## Fase 0 - Preparacion del repositorio

- [x] Verificar estado local con `git status`.
- [x] Revisar remotos actuales con `git remote -v`.
- [x] Configurar remoto GitHub hacia `https://github.com/compania-pari/CEROHUELLA_IA`.
- [x] Verificar acceso al repositorio con el plugin `@github`.
  - Repositorio encontrado: `compania-pari/CEROHUELLA_IA`, publico, rama por defecto `main`, permisos de administracion y escritura disponibles. El repositorio esta vacio al momento de la verificacion.
- [x] Crear rama de trabajo `codex/github-azure-terraform-cicd`.
- [x] Identificar cambios locales existentes para no sobrescribir trabajo previo.
- [x] Definir si se conserva `develop` como rama de integracion o si todo parte desde `main`.
  - Decision inicial: conservar `develop` como rama de integracion y `main` como rama estable/release.
- [x] Documentar que Azure DevOps y AWS quedan como historico, no como CI/CD activo.
  - Decision inicial: mantener remotos `azure` y `aws` como referencia historica; usar el remoto `github` para el nuevo trabajo.

## Fase 1 - Diseno de arquitectura Azure

- [x] Definir convencion de nombres para recursos por ambiente: `dev`, `qa`, `prod`.
  - Documentado en `docs/arquitectura-azure.md`.
- [x] Definir region Azure principal.
  - Decision inicial: `eastus`.
- [x] Definir grupos de recursos por ambiente o grupo compartido mas recursos por ambiente.
  - Decision inicial: `rg-cerohuella-shared` y `rg-cerohuella-{env}`.
- [x] Definir estrategia de ACR: compartido entre ambientes o ACR por ambiente.
  - Decision inicial: ACR compartido `acrcerohuellashared`.
- [x] Definir estrategia PostgreSQL: servidor por ambiente o servidor compartido con bases separadas.
  - Decision inicial: PostgreSQL Flexible Server por ambiente.
- [x] Definir estrategia de secretos: GitHub Environments + Container App secrets.
- [x] Definir tags obligatorios: proyecto, ambiente, owner, managedBy, costo.
- [x] Documentar la excepcion OECE: Python/FastAPI + IA/DLP fuera de pila Java/Angular/Oracle, sustentada por el dominio de IA y procesamiento PDF.

## Fase 2 - Bootstrap Terraform

- [x] Crear estructura `infra/terraform`.
- [x] Crear `infra/terraform/bootstrap` para el backend remoto.
- [x] Crear script PowerShell o README operativo para crear backend con Azure CLI.
  - Artefactos creados: `infra/terraform/bootstrap/create-backend.ps1`, `infra/terraform/bootstrap/README.md`.
- [x] Crear resource group de estado Terraform.
  - Automatizado en script; no ejecutado aun para evitar crear recursos Azure sin confirmacion explicita.
- [x] Crear storage account de estado Terraform.
  - Automatizado en script; no ejecutado aun.
- [x] Crear blob container para `tfstate`.
  - Automatizado en script; no ejecutado aun.
- [x] Habilitar versionado/proteccion de estado si aplica.
  - Automatizado en script con versionado de blobs y retencion de borrado.
- [x] Documentar comandos `terraform init`, `plan` y `apply`.
  - Documentado en `infra/terraform/README.md`.

## Fase 3 - Modulos Terraform

- [x] Crear modulo `resource_group`.
- [x] Crear modulo `container_registry`.
- [x] Crear modulo `log_analytics`.
- [x] Crear modulo `application_insights`.
- [x] Crear modulo `container_apps_environment`.
- [x] Crear modulo `container_app`.
- [x] Crear modulo `postgresql_flexible_server`.
- [x] Crear modulo `managed_identity` y permisos ACR Pull.
- [x] Crear modulo de alertas Azure Monitor.
- [x] Definir outputs utiles: FQDN de Container App, login server ACR, connection strings, nombres de recursos.
  - Tambien se agrego modulo `network` para VNet, subnet de Container Apps y subnet delegada de PostgreSQL.
  - Validacion: `terraform fmt -recursive infra\terraform` y `terraform validate` por modulo con provider `azurerm v4.77.0`.

## Fase 4 - Ambientes Terraform

- [x] Crear `infra/terraform/envs/dev`.
- [x] Crear `infra/terraform/envs/qa`.
- [x] Crear `infra/terraform/envs/prod`.
  - Tambien se creo `infra/terraform/envs/shared` para el ACR compartido.
- [x] Crear variables comunes y especificas por ambiente.
- [x] Crear archivos `*.tfvars.example` sin secretos reales.
- [x] Configurar backend remoto separado por ambiente.
  - Se agregaron `backend.hcl.example` con keys separadas por ambiente.
- [x] Validar `terraform fmt`.
- [x] Validar `terraform validate`.
  - Validado `shared`, `dev`, `qa` y `prod` con `terraform init -backend=false` y `terraform validate`.
- [x] Generar `terraform plan` para `dev`.
  - Validado en copia temporal sin backend remoto, usando `dev.tfvars.example` con placeholders.
- [x] Generar `terraform plan` para `qa`.
  - Validado en copia temporal sin backend remoto, usando `qa.tfvars.example` con placeholders.
- [x] Generar `terraform plan` para `prod`.
  - Validado en copia temporal sin backend remoto, usando `prod.tfvars.example` con placeholders.

## Fase 5 - PostgreSQL y migraciones

- [ ] Crear PostgreSQL Flexible Server nuevo desde Terraform.
- [ ] Crear base de datos de la aplicacion por ambiente.
- [ ] Definir reglas de red/firewall necesarias para Container Apps.
- [ ] Definir usuario administrador sin exponer secretos.
- [ ] Configurar `DATABASE_URL` como secreto por ambiente.
- [ ] Evaluar si `alembic upgrade head` correra en pipeline o como paso operativo controlado.
- [ ] Documentar procedimiento de migraciones.

## Fase 6 - GitHub Environments y secretos

- [ ] Crear GitHub Environments: `dev`, `qa`, `prod`.
- [ ] Configurar aprobacion manual para `qa`.
- [ ] Configurar aprobacion manual para `prod`.
- [ ] Configurar OIDC entre GitHub Actions y Azure.
- [ ] Crear app registration o identidad federada para GitHub Actions.
- [ ] Agregar secrets/vars requeridos por ambiente:
  - [ ] `AZURE_CLIENT_ID`
  - [ ] `AZURE_TENANT_ID`
  - [ ] `AZURE_SUBSCRIPTION_ID`
  - [ ] `GOOGLE_CLOUD_PROJECT_ID`
  - [ ] `GOOGLE_APPLICATION_CREDENTIALS_B64`
  - [ ] `POSTGRES_ADMIN_PASSWORD`
  - [ ] `DATABASE_URL` si no se compone desde Terraform.
- [ ] Evitar secretos largos de Azure usando OIDC.

## Fase 7 - Workflow CI

- [ ] Crear `.github/workflows/ci.yml`.
- [ ] Ejecutar checkout.
- [ ] Configurar Python 3.12.
- [ ] Instalar dependencias con `python -m pip install -e .[dev]`.
- [ ] Validar importacion de FastAPI.
- [ ] Ejecutar `pytest`.
- [ ] Publicar resultados JUnit.
- [ ] Construir imagen Docker.
- [ ] Ejecutar escaneo basico de imagen con Trivy.
- [ ] Publicar resumen del build.

## Fase 8 - Workflow Terraform

- [ ] Crear `.github/workflows/terraform.yml`.
- [ ] Ejecutar `terraform fmt -check`.
- [ ] Ejecutar `terraform init`.
- [ ] Ejecutar `terraform validate`.
- [ ] Ejecutar `terraform plan`.
- [ ] Permitir `terraform apply` por environment.
- [ ] Separar ejecucion por `dev`, `qa` y `prod`.
- [ ] Usar OIDC con `azure/login`.
- [ ] Documentar como revisar planes antes de aplicar.

## Fase 9 - Workflow CD dev -> qa -> prod

- [ ] Crear `.github/workflows/deploy.yml`.
- [ ] Construir imagen con tag por SHA corto.
- [ ] Publicar imagen en ACR.
- [ ] Desplegar automaticamente a `dev`.
- [ ] Ejecutar smoke test contra `/health` en `dev`.
- [ ] Promover a `qa` con aprobacion manual.
- [ ] Ejecutar smoke test contra `/health` en `qa`.
- [ ] Promover a `prod` con aprobacion manual.
- [ ] Ejecutar smoke test contra `/health` en `prod`.
- [ ] Publicar URLs finales por ambiente en el resumen del workflow.

## Fase 10 - Observabilidad basica Azure

- [ ] Crear Log Analytics Workspace por ambiente o compartido.
- [ ] Conectar Container Apps Environment a Log Analytics.
- [ ] Crear Application Insights.
- [ ] Agregar `APPLICATIONINSIGHTS_CONNECTION_STRING` como secreto o variable segura.
- [ ] Instrumentar FastAPI con Azure Monitor OpenTelemetry.
- [ ] Configurar nombre de servicio con `OTEL_SERVICE_NAME`.
- [ ] Enviar logs de aplicacion a stdout en formato claro para Log Analytics.
- [ ] Definir consultas KQL iniciales para requests, errores, excepciones y logs de contenedor.
- [ ] Crear alertas iniciales:
  - [ ] API no saludable.
  - [ ] Errores HTTP 5xx.
  - [ ] Latencia alta.
  - [ ] Fallos o reinicios de Container App.
  - [ ] Uso alto de CPU o memoria.
  - [ ] PostgreSQL con CPU, storage o conexiones altas.
- [ ] Documentar decision de no desplegar Prometheus/Grafana/Loki/Jaeger en esta etapa.

## Fase 11 - Cambios minimos en aplicacion

- [ ] Agregar dependencias de OpenTelemetry/Azure Monitor en `pyproject.toml`.
- [ ] Crear modulo de instrumentacion, por ejemplo `app/core/observability.py`.
- [ ] Activar instrumentacion solo si existe `APPLICATIONINSIGHTS_CONNECTION_STRING`.
- [ ] Instrumentar FastAPI sin romper pruebas locales.
- [ ] Agregar request id/correlation id si no introduce riesgo excesivo.
- [ ] Mantener `STORAGE_ROOT` en disco local como decision temporal.
- [ ] No mover PDFs a Azure Files en esta etapa.
- [ ] Actualizar pruebas si el cambio afecta inicializacion de la app.

## Fase 12 - Seguridad y cumplimiento

- [ ] Confirmar que `.env`, credenciales y PDFs siguen ignorados por Git.
- [ ] Revisar que Terraform no exponga secretos en variables por defecto.
- [ ] Usar variables sensibles en Terraform.
- [ ] Evitar imprimir secretos en GitHub Actions.
- [ ] Agregar Trivy al CI.
- [ ] Evaluar `pip-audit` como paso no bloqueante o bloqueante.
- [ ] Documentar riesgos residuales: almacenamiento local, min replicas, costos, firewall PostgreSQL.
- [ ] Validar que la comunicacion publica use HTTPS administrado por Azure Container Apps.

## Fase 13 - Documentacion

- [ ] Crear `docs/github-azure-cicd.md`.
- [ ] Crear `docs/terraform-azure.md`.
- [ ] Crear `docs/observabilidad-azure.md`.
- [ ] Actualizar `README.md` con resumen del nuevo flujo.
- [ ] Documentar comandos operativos:
  - [ ] Bootstrap Terraform.
  - [ ] Plan/apply por ambiente.
  - [ ] Ejecucion CI.
  - [ ] Promocion dev -> qa -> prod.
  - [ ] Consulta de logs y trazas.
- [ ] Documentar rollback basico de Container Apps.
- [ ] Documentar limpieza de recursos para controlar costos.

## Fase 14 - Validacion local

- [ ] Ejecutar `pytest`.
- [ ] Ejecutar build Docker local si aplica.
- [ ] Ejecutar `terraform fmt -check`.
- [ ] Ejecutar `terraform validate`.
- [ ] Generar plan Terraform para `dev`.
- [ ] Revisar que no haya secretos en cambios con `git diff`.
- [ ] Revisar archivos nuevos con `git status`.

## Fase 15 - Publicacion en GitHub

- [ ] Confirmar rama de trabajo.
- [ ] Preparar commit con alcance claro.
- [ ] Subir rama a `compania-pari/CEROHUELLA_IA`.
- [ ] Crear pull request con el plugin `@github`.
- [ ] Incluir resumen, pruebas ejecutadas y riesgos residuales.
- [ ] Solicitar revision antes de aplicar infraestructura real si corresponde.

## Preguntas no bloqueantes para decidir durante la implementacion

- [x] Definir si `dev` se despliega desde `develop` y `prod` desde `main`, o si se usa `main` con promocion manual.
  - Decision inicial: `develop` despliega a `dev`; `main` promueve a `qa` y `prod` con aprobaciones.
- [x] Definir si ACR sera compartido o uno por ambiente.
  - Decision inicial: ACR compartido.
- [x] Definir si PostgreSQL sera servidor por ambiente o servidor unico con bases por ambiente.
  - Decision inicial: servidor por ambiente.
- [ ] Definir si las alertas notificaran por correo, webhook, Teams u otro canal.
- [ ] Definir presupuesto/cotas para evitar costos inesperados.

## Criterios de terminado

- [ ] Infraestructura nueva definida en Terraform y validada.
- [ ] GitHub Actions ejecuta CI correctamente.
- [ ] GitHub Actions despliega `dev -> qa -> prod` con aprobaciones.
- [ ] Imagen Docker se publica en ACR.
- [ ] Container App responde `/health` por ambiente.
- [ ] PostgreSQL nuevo queda provisionado y conectado.
- [ ] Observabilidad basica visible en Azure Monitor/Application Insights.
- [ ] Alertas basicas creadas.
- [ ] Documentacion operativa completa.
- [ ] Codigo publicado en `compania-pari/CEROHUELLA_IA`.
