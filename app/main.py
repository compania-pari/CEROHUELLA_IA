from fastapi import FastAPI
from fastapi.openapi.utils import get_openapi

from app.api.v1.redactions import router as redactions_router
from app.core.config import get_settings
from app.core.gcp_credentials import configure_google_application_credentials


settings = get_settings()
configure_google_application_credentials(settings)

app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    description="API para anonimizar PDFs y auditar solicitudes realizadas4.",
)
app.openapi_version = "3.0.3"

app.include_router(redactions_router, prefix="/api/v1")


def custom_openapi() -> dict:
    if app.openapi_schema:
        return app.openapi_schema

    schema = get_openapi(
        title=app.title,
        version=app.version,
        description=app.description,
        routes=app.routes,
    )
    schema["openapi"] = "3.0.3"

    for component in schema.get("components", {}).get("schemas", {}).values():
        for property_schema in component.get("properties", {}).values():
            items = property_schema.get("items")
            if isinstance(items, dict) and items.pop("contentMediaType", None) == "application/octet-stream":
                items["format"] = "binary"
            if property_schema.pop("contentMediaType", None) == "application/octet-stream":
                property_schema["format"] = "binary"

    app.openapi_schema = schema
    return app.openapi_schema


app.openapi = custom_openapi


@app.get(
    "/health",
    tags=["health"],
    summary="Verificar que la API esta activa",
    description=(
        "Endpoint liviano para confirmar que la aplicacion FastAPI esta levantada "
        "y puede responder peticiones HTTP. No valida la conexion a PostgreSQL, "
        "Google Cloud DLP ni Poppler."
    ),
    response_description="Estado basico de la aplicacion.",
)
def healthcheck() -> dict[str, str]:
    return {"status": "ok"}
