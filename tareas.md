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
- [x] Crear rama de trabajo temporal `codex/github-azure-terraform-cicd`.
  - Correccion posterior: esta rama no forma parte del flujo oficial; el remoto temporal fue eliminado y el flujo permanente queda en `develop` y `main`.
- [x] Identificar cambios locales existentes para no sobrescribir trabajo previo.
- [x] Definir si se conserva `develop` como rama de integracion o si todo parte desde `main`.
  - Decision inicial: conservar `develop` como rama de integracion y `main` como rama estable/release.
- [x] Documentar que Azure DevOps y AWS quedan como historico, no como CI/CD activo.
  - Decision inicial: mantener remotos `azure` y `aws` como referencia historica; usar el remoto `github` para el nuevo trabajo.

## Fase 1 - Diseno de arquitectura Azure

- [x] Definir convencion de nombres para recursos por ambiente: `dev`, `qa`, `prod`.
  - Documentado en `docs/arquitectura-azure.md`.
- [x] Definir region Azure principal.
  - Decision inicial ajustada: `eastus2` para runtime por restriccion `LocationIsOfferRestricted` de PostgreSQL Flexible Server en `eastus`.
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

- [x] Crear PostgreSQL Flexible Server nuevo desde Terraform.
  - Implementado en `infra/terraform/modules/postgresql_flexible_server` y ambientes `dev`, `qa`, `prod`.
- [x] Crear base de datos de la aplicacion por ambiente.
  - Base `cerohuella` creada por Terraform en cada ambiente.
- [x] Definir reglas de red/firewall necesarias para Container Apps.
  - Decision: PostgreSQL privado, VNet por ambiente, subnet delegada y DNS privado. Sin exposicion publica por defecto.
- [x] Definir usuario administrador sin exponer secretos.
  - Usuario parametrizado; password como variable sensible y placeholder en `*.tfvars.example`.
- [x] Configurar `DATABASE_URL` como secreto por ambiente.
  - Compuesto en Terraform y montado como secret env `DATABASE_URL`.
- [x] Evaluar si `alembic upgrade head` correra en pipeline o como paso operativo controlado.
  - Decision: ejecutar migraciones como paso controlado dentro de Azure, preferentemente con Container Apps Job, no desde Terraform.
- [x] Documentar procedimiento de migraciones.
  - Documentado en `docs/postgresql-migraciones.md`.

## Fase 6 - GitHub Environments y secretos

- [x] Crear GitHub Environments: `dev`, `qa`, `prod`.
  - Automatizado en `infra/github/configure-environments.ps1`; no ejecutado aun porque requiere token GitHub y aprobadores reales.
- [x] Configurar aprobacion manual para `qa`.
  - Soportado por script mediante reviewers por ID.
- [x] Configurar aprobacion manual para `prod`.
  - Soportado por script mediante reviewers por ID.
- [x] Configurar OIDC entre GitHub Actions y Azure.
  - Automatizado en `infra/azure/create-github-oidc-app.ps1`; no ejecutado aun porque crea app registration y asignaciones RBAC reales.
- [x] Crear app registration o identidad federada para GitHub Actions.
  - Script crea app registration, service principal y credenciales federadas por environment.
- [x] Agregar secrets/vars requeridos por ambiente:
  - [x] `AZURE_CLIENT_ID`
  - [x] `AZURE_TENANT_ID`
  - [x] `AZURE_SUBSCRIPTION_ID`
  - [x] `GOOGLE_CLOUD_PROJECT_ID`
  - [x] `GOOGLE_APPLICATION_CREDENTIALS_B64`
  - [x] `POSTGRES_ADMIN_PASSWORD`
  - [x] `DATABASE_URL` si no se compone desde Terraform.
  - Documentado en `docs/github-environments-oidc.md`; valores reales no versionados.
- [x] Evitar secretos largos de Azure usando OIDC.

## Fase 7 - Workflow CI

- [x] Crear `.github/workflows/ci.yml`.
- [x] Ejecutar checkout.
- [x] Configurar Python 3.12.
- [x] Instalar dependencias con `python -m pip install -e .[dev]`.
- [x] Validar importacion de FastAPI.
- [x] Ejecutar `pytest`.
- [x] Publicar resultados JUnit.
  - Publicado como artifact `pytest-results`.
- [x] Construir imagen Docker.
- [x] Ejecutar escaneo basico de imagen con Trivy.
  - Publicado como artifact `security-reports`; inicialmente no bloqueante.
- [x] Publicar resumen del build.

## Fase 8 - Workflow Terraform

- [x] Crear `.github/workflows/terraform.yml`.
- [x] Ejecutar `terraform fmt -check`.
- [x] Ejecutar `terraform init`.
- [x] Ejecutar `terraform validate`.
- [x] Ejecutar `terraform plan`.
- [x] Permitir `terraform apply` por environment.
- [x] Separar ejecucion por `dev`, `qa` y `prod`.
  - Tambien soporta `shared` para ACR compartido.
- [x] Usar OIDC con `azure/login`.
- [x] Documentar como revisar planes antes de aplicar.
  - El workflow publica artifact `terraform-plan-{environment}` antes de aplicar.

## Fase 9 - Workflow CD develop -> dev, main -> qa

- [x] Crear `.github/workflows/deploy.yml`.
- [x] Construir imagen con tag por SHA corto.
- [x] Publicar imagen en ACR.
- [x] Desplegar automaticamente a `dev`.
- [x] Ejecutar smoke test contra `/health` en `dev`.
- [x] Promover a `qa` con aprobacion manual.
- [x] Ejecutar smoke test contra `/health` en `qa`.
- [x] Promover a `prod` con aprobacion manual.
  - Decision actual: `prod` queda manual por `workflow_dispatch` y environment `prod`; no se ejecuta automaticamente desde `main`.
  - Ejecutado con workflow `CD`, run `27985079578`.
- [x] Ejecutar smoke test contra `/health` en `prod`.
- [x] Publicar URLs finales por ambiente en el resumen del workflow.

## Fase 10 - Observabilidad basica Azure

- [x] Crear Log Analytics Workspace por ambiente o compartido.
- [x] Conectar Container Apps Environment a Log Analytics.
- [x] Crear Application Insights.
- [x] Agregar `APPLICATIONINSIGHTS_CONNECTION_STRING` como secreto o variable segura.
- [x] Instrumentar FastAPI con Azure Monitor OpenTelemetry.
- [x] Configurar nombre de servicio con `OTEL_SERVICE_NAME`.
- [x] Enviar logs de aplicacion a stdout en formato claro para Log Analytics.
- [x] Definir consultas KQL iniciales para requests, errores, excepciones y logs de contenedor.
- [x] Crear alertas iniciales:
  - [x] API no saludable.
  - [x] Errores HTTP 5xx.
  - [x] Latencia alta.
  - [x] Fallos o reinicios de Container App.
  - [x] Uso alto de CPU o memoria.
  - [x] PostgreSQL con CPU, storage o conexiones altas.
- [x] Documentar decision de no desplegar Prometheus/Grafana/Loki/Jaeger en esta etapa.

## Fase 11 - Cambios minimos en aplicacion

- [x] Agregar dependencias de OpenTelemetry/Azure Monitor en `pyproject.toml`.
- [x] Crear modulo de instrumentacion, por ejemplo `app/core/observability.py`.
- [x] Activar instrumentacion solo si existe `APPLICATIONINSIGHTS_CONNECTION_STRING`.
- [x] Instrumentar FastAPI sin romper pruebas locales.
- [x] Agregar request id/correlation id si no introduce riesgo excesivo.
- [x] Mantener `STORAGE_ROOT` en disco local como decision temporal.
- [x] No mover PDFs a Azure Files en esta etapa.
- [x] Actualizar pruebas si el cambio afecta inicializacion de la app.

## Fase 12 - Seguridad y cumplimiento

- [x] Confirmar que `.env`, credenciales y PDFs siguen ignorados por Git.
- [x] Revisar que Terraform no exponga secretos en variables por defecto.
- [x] Usar variables sensibles en Terraform.
- [x] Evitar imprimir secretos en GitHub Actions.
- [x] Agregar Trivy al CI.
- [x] Evaluar `pip-audit` como paso no bloqueante o bloqueante.
  - Decision inicial: `pip-audit` no bloqueante, con reporte JSON como artifact.
- [x] Documentar riesgos residuales: almacenamiento local, min replicas, costos, firewall PostgreSQL.
- [x] Validar que la comunicacion publica use HTTPS administrado por Azure Container Apps.

## Fase 13 - Documentacion

- [x] Crear `docs/github-azure-cicd.md`.
- [x] Crear `docs/terraform-azure.md`.
- [x] Crear `docs/observabilidad-azure.md`.
- [x] Actualizar `README.md` con resumen del nuevo flujo.
- [x] Documentar comandos operativos:
  - [x] Bootstrap Terraform.
  - [x] Plan/apply por ambiente.
  - [x] Ejecucion CI.
  - [x] Promocion dev -> qa -> prod.
  - [x] Consulta de logs y trazas.
- [x] Documentar rollback basico de Container Apps.
- [x] Documentar limpieza de recursos para controlar costos.

## Fase 14 - Validacion local

- [x] Ejecutar `pytest`.
  - Resultado: 12 pruebas pasaron.
- [x] Ejecutar build Docker local si aplica.
  - Resultado: no ejecutado localmente porque `docker` no esta disponible en el PATH de esta sesion. El build queda cubierto por GitHub Actions.
- [x] Ejecutar `terraform fmt -check`.
  - Resultado: `terraform fmt -check -recursive infra\terraform` paso correctamente.
- [x] Ejecutar `terraform validate`.
  - Resultado: `shared`, `dev`, `qa` y `prod` validaron correctamente con `terraform init -backend=false`.
- [x] Generar plan Terraform para `dev`.
  - Resultado: plan validado en copia temporal sin backend remoto y con `dev.tfvars.example`; 24 recursos a crear.
- [x] Revisar que no haya secretos en cambios con `git diff`.
  - Resultado: `git diff --check` paso y busqueda de patrones sensibles no encontro secretos reales.
- [x] Revisar archivos nuevos con `git status`.
  - Resultado: solo archivos ignorados locales como `.env`, `.terraform`, caches y PDFs procesados permanecen fuera de Git.

## Fase 15 - Publicacion en GitHub

- [x] Confirmar rama de trabajo.
  - Rama temporal usada durante la implementacion inicial: `codex/github-azure-terraform-cicd`.
- [x] Preparar commit con alcance claro.
  - Trabajo separado en commits por fase: Terraform, workflows, observabilidad, seguridad, documentacion y validacion.
- [x] Subir rama a `compania-pari/CEROHUELLA_IA`.
  - Se publico `develop` como rama base porque el repositorio GitHub estaba vacio.
  - Se publico `codex/github-azure-terraform-cicd` con tracking remoto para el PR inicial; luego se integro a `develop` y se elimino del remoto para dejar solo ramas permanentes.
- [x] Crear pull request con el plugin `@github`.
  - El conector `@github` devolvio `403 Resource not accessible by integration` al crear PR.
  - PR creado con `gh` autenticado como fallback autorizado en la sesion: https://github.com/compania-pari/CEROHUELLA_IA/pull/1
- [x] Incluir resumen, pruebas ejecutadas y riesgos residuales.
  - Incluido en el cuerpo del PR.
- [x] Solicitar revision antes de aplicar infraestructura real si corresponde.
  - PR creado como draft para revision previa. No se ejecuto `terraform apply` ni se crearon recursos Azure reales.
  - Checks GitHub iniciales: CI exitoso y Terraform `fmt/validate` exitoso en `shared`, `dev`, `qa` y `prod`.

## Estado de despliegue real en Azure

- [x] Bootstrap Terraform remoto creado en Azure.
  - Backend: `rg-cerohuella-tfstate`, storage account `stcerohuellatf1043272f`, container `tfstate`.
- [x] Ambiente `shared` aplicado con Terraform.
  - ACR creado: `acrcerohuellashared.azurecr.io`.
- [x] Imagen base de la aplicacion publicada en ACR para habilitar el primer despliegue.
  - Repositorio/tag: `cerohuella-ia:latest`.
- [x] Ambiente `dev` aplicado con Terraform.
  - Resource group: `rg-cerohuella-dev`.
  - Container App: `ca-cerohuella-api-dev`.
  - PostgreSQL Flexible Server: `psql-cerohuella-dev-eus2`.
  - Log Analytics: `law-cerohuella-dev-eus2`.
  - Application Insights: `appi-cerohuella-dev-eus2`.
  - Alertas basicas de Azure Monitor creadas para API y PostgreSQL.
- [x] Verificacion `dev` contra `/health`.
  - URL: `https://ca-cerohuella-api-dev.gentleriver-3e399988.eastus2.azurecontainerapps.io/health`.
  - Resultado: `HTTP 200` con `{"status":"ok"}`.
- [x] Ambiente `qa` aplicado con Terraform.
  - Resource group: `rg-cerohuella-qa`.
  - Container App: `ca-cerohuella-api-qa`.
  - PostgreSQL Flexible Server: `psql-cerohuella-qa`.
  - Log Analytics: `law-cerohuella-qa`.
  - Application Insights: `appi-cerohuella-qa`.
  - Alertas basicas de Azure Monitor creadas para API y PostgreSQL.
  - Por cuota/costo academico, QA reutiliza el Container Apps Environment `cae-cerohuella-dev` y se conecta a PostgreSQL QA mediante VNet peering y Private DNS link.
- [x] Verificacion `qa` contra `/health`.
  - URL: `https://ca-cerohuella-api-qa.gentleriver-3e399988.eastus2.azurecontainerapps.io/health`.
  - Resultado: `HTTP 200` con `{"status":"ok"}`.
- [x] Ambiente `prod` aplicado con Terraform.
  - Resource group: `rg-cerohuella-prod`.
  - Container App: `ca-cerohuella-api-prod`.
  - PostgreSQL Flexible Server: `psql-cerohuella-prod`.
  - Log Analytics: `law-cerohuella-prod`.
  - Application Insights: `appi-cerohuella-prod`.
  - Alertas basicas de Azure Monitor creadas para API y PostgreSQL.
  - Por cuota/costo academico, PROD reutiliza el Container Apps Environment `cae-cerohuella-dev` y se conecta a PostgreSQL PROD mediante VNet peering y Private DNS link.
- [x] Verificacion `prod` contra `/health`.
  - URL: `https://ca-cerohuella-api-prod.gentleriver-3e399988.eastus2.azurecontainerapps.io/health`.
  - Resultado: smoke test exitoso en GitHub Actions `Apply prod academic` y `CD`.
- [x] Observabilidad `prod` validada.
  - Log Analytics `law-cerohuella-prod` recibio datos recientes en `AppTraces`, `AppPerformanceCounters` y `AppMetrics`.

## Preguntas no bloqueantes para decidir durante la implementacion

- [x] Definir flujo de ramas permanente.
  - Decision corregida: `develop` despliega a `dev`; PR `develop -> main` valida la promocion; merge a `main` despliega a `qa` con aprobacion del environment. `prod` queda manual por `workflow_dispatch`.
- [x] Definir si ACR sera compartido o uno por ambiente.
  - Decision inicial: ACR compartido.
- [x] Definir si PostgreSQL sera servidor por ambiente o servidor unico con bases por ambiente.
  - Decision inicial: servidor por ambiente.
- [ ] Definir si las alertas notificaran por correo, webhook, Teams u otro canal.
- [ ] Definir presupuesto/cotas para evitar costos inesperados.

## Criterios de terminado

- [x] Infraestructura nueva definida en Terraform y validada.
- [x] GitHub Actions ejecuta CI correctamente.
- [x] GitHub Actions despliega `develop -> dev` y `main -> qa` con aprobacion de `qa`.
- [x] Imagen Docker se publica en ACR para `dev`.
- [x] Imagen Docker se reutiliza desde ACR para `qa`.
- [x] Imagen Docker se publica/promueve para `prod`.
- [x] Container App responde `/health` en `dev`.
- [x] Container App responde `/health` en `qa`.
- [x] Container App responde `/health` en `prod`.
- [x] PostgreSQL nuevo queda provisionado para `dev`.
- [x] PostgreSQL nuevo queda provisionado para `qa`.
- [x] PostgreSQL nuevo queda provisionado para `prod`.
- [x] Observabilidad basica creada en Azure Monitor/Application Insights para `dev`.
- [x] Observabilidad basica creada en Azure Monitor/Application Insights para `qa`.
- [x] Observabilidad basica creada en Azure Monitor/Application Insights para `prod`.
- [x] Alertas basicas creadas para `dev`.
- [x] Alertas basicas creadas para `qa`.
- [x] Alertas basicas creadas para `prod`.
- [x] Documentacion operativa completa.
- [x] Codigo publicado en `compania-pari/CEROHUELLA_IA`.
