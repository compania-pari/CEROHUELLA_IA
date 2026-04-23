from fastapi import FastAPI

from app.api.v1.redactions import router as redactions_router
from app.core.config import get_settings


settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    description="API para anonimizar PDFs y auditar solicitudes.",
)

app.include_router(redactions_router, prefix="/api/v1")


@app.get("/health", tags=["health"])
def healthcheck() -> dict[str, str]:
    return {"status": "ok"}

