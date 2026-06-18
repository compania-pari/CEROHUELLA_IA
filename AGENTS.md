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

## Despliegue Actual

La API esta desplegada en Azure Container App.

Recursos principales:

- Resource group: `rg-cerohuella-dev`
- Container App: `ca-cerohuella-api-dev`
- Azure Container Registry: `acrcerohuella`
- Imagen: `acrcerohuella.azurecr.io/cerohuella-ia`
- Azure PostgreSQL: `cerohuella-bd`
- URL Azure: `https://ca-cerohuella-api-dev.victorioussea-9b4cd674.eastus.azurecontainerapps.io`
- Health Azure: `https://ca-cerohuella-api-dev.victorioussea-9b4cd674.eastus.azurecontainerapps.io/health`
- Swagger Azure: `https://ca-cerohuella-api-dev.victorioussea-9b4cd674.eastus.azurecontainerapps.io/docs`

Para recrear Azure desde cero o reconfigurar el despliegue, usar:

- `docs/azure-recreate.md`: guia operativa de recreacion.
- `infra/azure/README.md`: orden y proposito de scripts.
- `infra/azure/create-resources.ps1`: crea recursos base de Azure.
- `infra/azure/configure-containerapp.ps1`: crea/configura Container App, secretos y variables.
- `infra/azure/create-devops-service-connection.ps1`: crea Service Connection en Azure DevOps.
- `infra/azure/create-devops-release.ps1`: recrea Release clasico automatico.

Los scripts son plantillas operativas con parametros; no contienen secretos reales.

Flujo:

```text
Merge a main
 -> build_cerohuella_ia
 -> pruebas con pytest
 -> construccion de imagen Docker
 -> publicacion en ACR
 -> artifact drop/image.env
 -> release_cerohuella_ia_dev
 -> despliegue en Azure Container App
```

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
