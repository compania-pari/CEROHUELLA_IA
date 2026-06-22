# Guia Para Agentes

Este archivo resume el contexto minimo para trabajar en el proyecto `cerohuella_ia`.

## Proyecto

API en Python con FastAPI para anonimizar documentos PDF mediante Google Cloud DLP. Permite procesar un PDF individual o varios PDFs por lote, registra auditoria en PostgreSQL y almacena archivos de entrada/salida en disco local.

## Comandos Basicos

Instalar dependencias:

```bash
python -m pip install -e .[dev]
```

Ejecutar migraciones:

```bash
alembic upgrade head
```

Levantar la API:

```bash
uvicorn app.main:app --reload
```

Ejecutar pruebas:

```bash
pytest
```

## Configuracion Local

La configuracion local se lee desde `.env`. Ese archivo no debe subirse al repositorio.

Variables principales:

- `DATABASE_URL`
- `GOOGLE_CLOUD_PROJECT_ID`
- `GOOGLE_APPLICATION_CREDENTIALS`
- `GOOGLE_APPLICATION_CREDENTIALS_B64`
- `GOOGLE_APPLICATION_CREDENTIALS_PATH`
- `STORAGE_ROOT`
- `MAX_FILE_SIZE_MB`
- `MAX_BATCH_FILES`

## Endpoints Principales

- `POST /api/v1/redactions/single`: procesa un PDF individual.
- `POST /api/v1/redactions/batch`: registra y procesa varios PDFs.
- `GET /api/v1/redactions/{request_id}`: consulta estado de solicitud.
- `GET /api/v1/redactions/{request_id}/files`: lista archivos de una solicitud.
- `GET /api/v1/redactions/files/{file_id}/download`: descarga PDF redactado.
- `GET /health`: verifica que la API esta activa.

## Configuracion Google DLP

La app soporta credenciales Google por archivo local y por Base64.

En local puede usarse:

- `GOOGLE_APPLICATION_CREDENTIALS`

En Azure debe preferirse:

- `GOOGLE_APPLICATION_CREDENTIALS_B64`
- `GOOGLE_APPLICATION_CREDENTIALS_PATH`

No usar `GOOGLE_APPLICATION_CREDENTIALS_JSON` en Azure porque el JSON crudo puede romperse por comillas al guardarse como secreto.

## Despliegue Actual GitHub + Azure + Terraform

El despliegue vigente se esta migrando a GitHub Actions como unico CI/CD y Azure como plataforma de runtime, base de datos, registry y observabilidad.

Repositorio GitHub:

- Owner/repo: `compania-pari/CEROHUELLA_IA`
- Ramas permanentes: `develop` para integracion y `main` como rama estable.
- Flujo vigente: push a `develop` despliega `dev`; PR `develop -> main` valida la promocion; merge a `main` despliega `qa` con aprobacion del environment.
- `prod` queda manual por `workflow_dispatch` y no se ejecuta automaticamente desde `main`.
- Remoto local principal para este trabajo: `github`

Terraform:

- Codigo: `infra/terraform`
- Backend remoto: `rg-cerohuella-tfstate`
- Storage account de estado: `stcerohuellatf1043272f`
- Container de estado: `tfstate`
- Keys usadas: `envs/shared/terraform.tfstate`, `envs/dev/terraform.tfstate`, `envs/qa/terraform.tfstate`, `envs/prod/terraform.tfstate`
- Workflows: `.github/workflows/terraform.yml`, `.github/workflows/ci.yml`, `.github/workflows/deploy.yml`
- `Plan or apply` aparece como `skipping` en PR o cuando no es `workflow_dispatch`; eso es esperado.

Recursos actuales aplicados:

- Shared:
  - Resource group: `rg-cerohuella-shared`
  - ACR: `acrcerohuellashared.azurecr.io`
  - Imagen inicial publicada: `cerohuella-ia:latest`
- Dev:
  - Resource group: `rg-cerohuella-dev`
  - Region runtime: `eastus2`
  - Container App: `ca-cerohuella-api-dev`
  - URL dev: `https://ca-cerohuella-api-dev.gentleriver-3e399988.eastus2.azurecontainerapps.io`
  - Health dev: `https://ca-cerohuella-api-dev.gentleriver-3e399988.eastus2.azurecontainerapps.io/health`
  - PostgreSQL Flexible Server: `psql-cerohuella-dev-eus2`
  - Database: `cerohuella`
  - Log Analytics: `law-cerohuella-dev-eus2`
  - Application Insights: `appi-cerohuella-dev-eus2`
  - Observabilidad: alertas basicas de API, Container App y PostgreSQL creadas por Terraform.
- QA:
  - Resource group: `rg-cerohuella-qa`
  - Region runtime: `eastus2`
  - Container App: `ca-cerohuella-api-qa`
  - URL QA: `https://ca-cerohuella-api-qa.gentleriver-3e399988.eastus2.azurecontainerapps.io`
  - Health QA: `https://ca-cerohuella-api-qa.gentleriver-3e399988.eastus2.azurecontainerapps.io/health`
  - PostgreSQL Flexible Server: `psql-cerohuella-qa`
  - Database: `cerohuella`
  - Log Analytics: `law-cerohuella-qa`
  - Application Insights: `appi-cerohuella-qa`
  - Observabilidad: alertas basicas de API, Container App y PostgreSQL creadas por Terraform.
  - Para mantener costos/cuotas academicas, QA reutiliza el Container Apps Environment `cae-cerohuella-dev` y se conecta a PostgreSQL QA con VNet peering y Private DNS link.

Ambientes pendientes:

- `prod`: aplicar solo con confirmacion explicita del usuario. Para uso academico debe reutilizar el Container Apps Environment de `dev` y mantener compute minimo.

## Lecciones Aprendidas GitHub + Terraform + Azure

- Usar `gh` como fallback operativo cuando el conector `@github` no permita alguna accion. En esta migracion, el conector devolvio `403 Resource not accessible by integration` al crear el PR.
- GitHub Actions usa OIDC contra Azure. No cargar secretos de Azure tipo client secret si OIDC ya esta configurado.
- Cargar secretos por GitHub Environments. Para Google DLP usar `GOOGLE_APPLICATION_CREDENTIALS_B64`, no JSON crudo.
- Flujo oficial probado:
  - Push a `develop`: ejecuta CI y CD solo hacia `dev`.
  - PR `develop -> main`: ejecuta validaciones de PR; no debe desplegar ambientes.
  - Merge a `main`: ejecuta CI y CD solo hacia `qa`.
  - `prod`: se ejecuta solo manualmente con `workflow_dispatch`.
- En la pantalla de PR, usar `base: main` y `compare: develop`. Esto significa integrar los cambios de `develop` hacia `main`.
- En un PR, el CI valida instalacion de dependencias, import de FastAPI, `pytest`, build Docker, `pip-audit` y Trivy. Si falla, no promover a `main`.
- Terraform automatico en PR/push solo corre cuando cambian archivos bajo `infra/terraform/**`; valida `terraform fmt`, `terraform init -backend=false` y `terraform validate` para `shared`, `dev`, `qa` y `prod`. No hace `plan`, no hace `apply` y no crea recursos.
- Terraform real se ejecuta manualmente desde GitHub Actions con `workflow_dispatch` en el workflow `Terraform`, eligiendo `environment` y `action` (`plan` o `apply`). `apply` puede crear o modificar recursos Azure.
- El job `Plan or apply` en el workflow Terraform aparece como `skipped` cuando no es `workflow_dispatch`; eso es correcto.
- Tras el merge del PR `develop -> main`, el CD de `main` debe mostrar `Deploy dev` como `skipped`, `Deploy qa` como `success` y `Deploy prod manually` como `skipped`.
- Para validar observabilidad, generar trafico contra `/health` y revisar Application Insights. En Azure en espanol, usar `Application Insights > Buscar` o `Investigacion > Busqueda de transacciones`; si solo aparece `View as: Traces`, los traces tambien sirven como evidencia de telemetria.
- Un `trace` es un evento o mensaje tecnico generado por la aplicacion; complementa a las `requests`, excepciones y metricas para diagnosticar comportamiento.
- La telemetria de Application Insights puede tardar algunos minutos en aparecer despues de generar trafico.
- En Azure Container Apps, la subnet debe tener delegacion a `Microsoft.App/environments`; sin eso falla la creacion del Container Apps Environment.
- Usar `eastus2` como region runtime. PostgreSQL Flexible Server fallo en `eastus` por `LocationIsOfferRestricted`.
- Mantener nombres con sufijo `eus2` cuando sea necesario para evitar conflictos de nombres reservados o recursos en soft-delete:
  - `law-cerohuella-dev-eus2`
  - `appi-cerohuella-dev-eus2`
  - `psql-cerohuella-dev-eus2`
- Antes del primer `terraform apply` de un ambiente con Container App, asegurar que exista la imagen referenciada en ACR. Para dev se publico `cerohuella-ia:latest`.
- Si `az acr build` falla localmente por `UnicodeEncodeError` al transmitir logs en Windows, revisar el resultado con `az acr task list-runs` y validar tags con `az acr repository show-tags`.
- Si Azure deja un Container App en `ProvisioningState=Failed`, Terraform puede no importarlo porque Azure bloquea la lectura de secretos con error `ResourceNotProvisioned`. En ese caso, si el recurso no tiene revision lista ni FQDN, pedir confirmacion y eliminar solo ese Container App fallido antes de relanzar `terraform apply`.
- En esta suscripcion academica, Azure devolvio `MaxNumberOfRegionalEnvironmentsInSubExceeded`: no permite mas de 1 Container Apps Environment en `eastus2`. Para QA se reutilizo el CAE de DEV y se agrego VNet peering + Private DNS link hacia PostgreSQL QA.
- Para PROD academico se debe seguir el mismo patron de QA: reutilizar `cae-cerohuella-dev`, crear VNet peering + Private DNS link hacia PostgreSQL PROD y mantener `min_replicas = 0`, `max_replicas = 1`, `0.5 CPU` y `1Gi`.
- Si un ambiente reutiliza un CAE compartido, validar el `/health` y recordar que los logs de sistema del Container Apps Environment pertenecen al workspace asociado al CAE compartido; la telemetria de aplicacion sigue yendo a Application Insights del ambiente.
- No borrar ni recrear recursos cloud sin confirmacion explicita del usuario. En DEV se elimino solamente `ca-cerohuella-api-dev` en estado fallido y luego Terraform lo recreo correctamente.
- Al validar DEV o QA, confirmar tres cosas: workflow Terraform exitoso, recurso Azure `Succeeded/Running`, y `/health` con `HTTP 200`.
- Despues de cada cambio documental o de infraestructura, actualizar `tareas.md` y subir el commit al PR para mantener trazabilidad.
- No dejar ramas temporales remotas como parte del flujo oficial; si se usan para apoyo, integrarlas a `develop` y eliminar el remoto al terminar.

## Despliegue Azure DevOps Historico

El despliegue anterior en Azure DevOps queda como referencia historica. No debe usarse como CI/CD activo mientras GitHub sea el destino de la migracion.

Recursos anteriores documentados:

- Resource group: `rg-cerohuella-dev`
- Container App: `ca-cerohuella-api-dev`
- Azure Container Registry anterior: `acrcerohuella`
- Imagen anterior: `acrcerohuella.azurecr.io/cerohuella-ia`
- Azure PostgreSQL anterior: `cerohuella-bd`
- URL Azure anterior: `https://ca-cerohuella-api-dev.victorioussea-9b4cd674.eastus.azurecontainerapps.io`

Scripts historicos:

- `docs/azure-recreate.md`: guia operativa de recreacion previa.
- `infra/azure/README.md`: orden y proposito de scripts previos.
- `infra/azure/create-resources.ps1`: crea recursos base de Azure.
- `infra/azure/configure-containerapp.ps1`: crea/configura Container App, secretos y variables.
- `infra/azure/create-devops-service-connection.ps1`: crea Service Connection en Azure DevOps.
- `infra/azure/create-devops-release.ps1`: recrea Release clasico automatico.

Los scripts son plantillas operativas con parametros; no contienen secretos reales.

## Azure DevOps

- Organizacion: `https://dev.azure.com/lparitOrg`
- Proyecto: `cerohuella_ia`
- Repositorio: `https://lparitOrg@dev.azure.com/lparitOrg/cerohuella_ia/_git/cerohuella_ia`
- Pipeline build: `build_cerohuella_ia`
- Archivo build: `.azuredevops/pipelines/build.yml`
- Release clasico: `release_cerohuella_ia_dev`
- Stage release: `Dev`
- Service connection: `sc-azure-cerohuella`

El build de Azure instala Python 3.12, instala dependencias, valida importacion de FastAPI, ejecuta `pytest`, construye imagen Docker, publica en ACR y genera `drop/image.env`.

## Despliegue AWS

Se implemento una version funcional en AWS usando la misma base de datos PostgreSQL de Azure.

Cuenta y region:

- AWS Account ID: `056639708411`
- Region principal: `us-east-1`

Repositorio de codigo:

- Servicio: AWS CodeCommit
- Repositorio: `cerohuella_ia`
- Ramas: `main` y `develop`
- Remoto local: `aws`
- URL SSH: `ssh://git-codecommit.us-east-1.amazonaws.com/v1/repos/cerohuella_ia`
- Flujo: PR de `develop` hacia `main`, con aprobacion.
- Template de aprobacion: `require-one-approval-main`
- Usuario administrador: `lpari`
- Usuario aprobador: `revisor`

Contenedor e imagen:

- Servicio: Amazon ECR
- Repositorio: `cerohuella-ia`
- URI: `056639708411.dkr.ecr.us-east-1.amazonaws.com/cerohuella-ia`
- Tag usado para despliegue: `latest`
- El `Dockerfile` usa imagen base desde ECR Public para evitar rate limits de Docker Hub: `public.ecr.aws/docker/library/python:3.12-slim`

Artifacts:

- Servicio: Amazon S3
- Bucket creado para artifacts del build: `cerohuella-ia-build-artifacts-056639708411`
- Bucket generado por CodePipeline: `codepipeline-us-east-1-daeff79cd8fc-46d8-82f3-93ea83d1baa7`
- El build genera `pytest-results.xml`, `artifacts/image.env` y una copia `.tar.gz` de la imagen Docker.

Build y pipeline:

- Servicio build: AWS CodeBuild
- Proyecto: `build-cerohuella-ia`
- Buildspec: `.awsdevops/pipelines/buildspec.yml`
- Servicio pipeline: AWS CodePipeline
- Pipeline: `pipeline-cerohuella-ia-build`
- Flujo: cambio en `main` -> CodePipeline -> CodeBuild -> pruebas -> Docker build -> push a ECR -> artifacts S3 -> redeploy ECS.

Ejecucion:

- Servicio usado: Amazon ECS Express Mode
- Cluster: `default`
- Servicio: `ecs-cerohuella-ia-dev`
- Puerto contenedor: `8000`
- Health check: `/health`
- CPU/memoria usadas en la prueba: `1 vCPU` / `2 GB`
- El servicio se probo correctamente con `/health`, `/docs`, carga de PDF y descarga de PDF redactado sin PII.
- Si el servicio fue eliminado para evitar costos, debe recrearse con imagen `056639708411.dkr.ecr.us-east-1.amazonaws.com/cerohuella-ia:latest`.

Variables de entorno requeridas en ECS:

- `APP_NAME`
- `APP_ENV`
- `APP_HOST`
- `APP_PORT`
- `DATABASE_URL`
- `GOOGLE_CLOUD_PROJECT_ID`
- `GOOGLE_APPLICATION_CREDENTIALS_PATH`
- `GOOGLE_APPLICATION_CREDENTIALS_B64`
- `STORAGE_ROOT`
- `MAX_FILE_SIZE_MB`
- `MAX_BATCH_FILES`

Notas AWS:

- `DATABASE_URL` apunta a Azure PostgreSQL `cerohuella-bd`; no mover ni revelar el secreto.
- Para pruebas se abrio temporalmente el firewall de Azure PostgreSQL a Internet. Cerrar o restringir esa regla cuando no se use AWS.
- No usar App Runner para recrear el despliegue; la cuenta mostro aviso de que App Runner ya no acepta clientes nuevos. Usar ECS Express Mode.
- Si el pipeline falla esperando ECS, revisar si el servicio tarda mas que el waiter. El buildspec ya maneja ese caso informando estado sin marcar rojo solo por timeout.
- Para minimizar costos, borrar/apagar ECS Express, Load Balancer, artifacts grandes en S3 e imagenes ECR que no se necesiten.

## Estructura Relevante

- `app/api/v1`: endpoints FastAPI.
- `app/services`: logica de negocio y procesamiento de PDFs.
- `app/repositories`: acceso a datos.
- `app/models`: modelos SQLAlchemy.
- `app/schemas`: modelos de entrada/salida Pydantic.
- `migrations/versions`: historial de cambios de base de datos con Alembic.
- `tests`: pruebas unitarias e integracion.
- `.azuredevops/pipelines`: pipelines de Azure DevOps.
- `.awsdevops/pipelines`: buildspec de AWS CodeBuild.

## Cuidados

- No subir `.env`, PDFs procesados, imagenes temporales ni credenciales.
- No modificar la BD manualmente si el cambio debe quedar versionado; usar migraciones Alembic.
- Para PR hacia `main`, validar primero con el pipeline de build y `pytest`.
- Mantener `main` como rama estable y usar `develop` para integracion.
- No hacer `push`, `commit`, cambios cloud destructivos ni modificaciones de infraestructura sin confirmacion del usuario.
- No revelar secretos de Azure, PostgreSQL, Google Cloud ni Service Principal.
- No revelar credenciales AWS, Access Key, Secret Access Key ni secretos de IAM.
- Si se modifica el pipeline, Dockerfile o dependencias, ejecutar `pytest`.

## Lineamientos OECE de Desarrollo

Cuando una tarea involucre desarrollo, revision, refactor, documentacion o base de datos de sistemas OECE/OSCE, aplicar los skills institucionales instalados globalmente.

### Skill principal

Usar `oece-lineamientos-desarrollo-software` como skill orquestador cuando la tarea sea general, de arquitectura, cumplimiento tecnico, diseno de solucion, excepciones tecnologicas, seguridad, disponibilidad, reportes o empaquetado.

### Skills especificos por tipo de trabajo

- Usar `oece-lineamientos-angular` para frontend Angular, TypeScript, SCSS, modulos, componentes, servicios, rutas, lazy loading, environments o build.
- Usar `oece-lineamientos-java-backend` para backend Java, Spring Boot, Java EE, paquetes, clases, interfaces, metodos, Javadoc, colecciones o Log4j.
- Usar `oece-lineamientos-datos-oracle` para modelamiento de datos, Oracle, DDL, tablas, columnas, indices, constraints, secuencias, triggers, packages, roles, profiles o nomenclatura de BD.
- Usar `oece-lineamientos-documentacion-trazabilidad` para contratos de servicio, comentarios, cabeceras, Javadoc, logs, reportes, recursos documentados y evidencia de cumplimiento.
- Usar tambien `documentacion-estandar-cambios` cuando el usuario pida documentar cambios en codigo con trazabilidad institucional, cabeceras historicas o bloques `INICIO/FIN`.

### Reglas de uso

- Antes de modificar codigo, identificar que lineamiento aplica segun el tipo de archivo o artefacto.
- Si una tarea cruza varias capas, usar el skill principal y luego los skills especificos necesarios.
- No duplicar reglas en el codigo si ya existe una convencion local mas especifica; armonizar el cambio con el proyecto.
- Si el proyecto es legacy o tiene una tecnologia distinta a Java, Angular u Oracle, tratarlo como posible excepcion y sustentarlo explicitamente.
- En revisiones, reportar incumplimientos con archivo, linea o artefacto afectado, y distinguir entre error, excepcion sustentada y deuda tecnica.
- Al cerrar una tarea, indicar brevemente que lineamientos OECE fueron aplicados o si no correspondian.

## MCP de IntelliJ

- Cuando el proyecto este abierto en IntelliJ y el MCP `intellij` este disponible, priorizarlo para navegacion de simbolos, busqueda de usos/referencias reales e inspecciones del IDE.
- Usar busqueda por archivos (`rg`) como apoyo o fallback cuando el MCP no este disponible o no tenga una herramienta adecuada.
