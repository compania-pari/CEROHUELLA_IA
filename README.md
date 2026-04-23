# CeroHuella IA

API en `FastAPI` para anonimizar documentos PDF mediante `Google Cloud DLP`, con auditoria en `PostgreSQL` y almacenamiento local de archivos.

## Caracteristicas

- Endpoint para procesar un PDF de forma sincrona.
- Endpoint para procesar varios PDFs de forma asincrona.
- Auditoria por solicitud y por archivo.
- Descarga posterior de resultados.
- Migraciones con Alembic.
- Arquitectura por capas para desacoplar el motor de redaccion.

## Requisitos

- Python 3.11+
- PostgreSQL
- Credenciales de Google Cloud con acceso a DLP
- Poppler instalado para `pdf2image`

## Variables de entorno

Usa `.env.example` como referencia:

- `DATABASE_URL`
- `GOOGLE_CLOUD_PROJECT_ID`
- `STORAGE_ROOT`
- `MAX_FILE_SIZE_MB`
- `MAX_BATCH_FILES`

## Instalacion

```bash
pip install -e .[dev]
alembic upgrade head
uvicorn app.main:app --reload
```

## Endpoints principales

- `POST /api/v1/redactions/single`
- `POST /api/v1/redactions/batch`
- `GET /api/v1/redactions/{request_id}`
- `GET /api/v1/redactions/{request_id}/files`
- `GET /api/v1/redactions/files/{file_id}/download`

## Pruebas

```bash
pytest
```

