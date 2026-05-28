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

## Estructura Relevante

- `app/api/v1`: endpoints FastAPI.
- `app/services`: logica de negocio y procesamiento de PDFs.
- `app/repositories`: acceso a datos.
- `app/models`: modelos SQLAlchemy.
- `app/schemas`: modelos de entrada/salida Pydantic.
- `migrations/versions`: historial de cambios de base de datos con Alembic.
- `tests`: pruebas unitarias e integracion.
- `.azuredevops/pipelines`: pipelines de Azure DevOps.

## Cuidados

- No subir `.env`, PDFs procesados, imagenes temporales ni credenciales.
- No modificar la BD manualmente si el cambio debe quedar versionado; usar migraciones Alembic.
- Para PR hacia `main`, validar primero con el pipeline de build y `pytest`.
- Mantener `main` como rama estable y usar `develop` para integracion.
- No hacer `push`, `commit`, cambios cloud destructivos ni modificaciones de infraestructura sin confirmacion del usuario.
- No revelar secretos de Azure, PostgreSQL, Google Cloud ni Service Principal.
- Si se modifica el pipeline, Dockerfile o dependencias, ejecutar `pytest`.
