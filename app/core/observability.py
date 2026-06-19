import logging
import sys
from uuid import uuid4

from fastapi import FastAPI, Request

from app.core.config import Settings


LOGGER = logging.getLogger(__name__)


def configure_logging() -> None:
    logging.basicConfig(
        level=logging.INFO,
        stream=sys.stdout,
        format="%(asctime)s %(levelname)s %(name)s %(message)s",
        force=False,
    )


def configure_observability(app: FastAPI, settings: Settings) -> None:
    configure_logging()
    _add_request_id_middleware(app)

    if getattr(app.state, "azure_monitor_configured", False):
        return

    if not settings.applicationinsights_connection_string:
        LOGGER.info("Azure Monitor disabled: APPLICATIONINSIGHTS_CONNECTION_STRING is not configured")
        return

    try:
        from azure.monitor.opentelemetry import configure_azure_monitor
    except ImportError:
        LOGGER.warning("Azure Monitor package is not installed; telemetry export disabled")
        return

    configure_azure_monitor(connection_string=settings.applicationinsights_connection_string)
    app.state.azure_monitor_configured = True
    LOGGER.info(
        "Azure Monitor enabled for service %s",
        settings.otel_service_name or settings.app_name,
    )


def _add_request_id_middleware(app: FastAPI) -> None:
    if getattr(app.state, "request_id_middleware_configured", False):
        return

    @app.middleware("http")
    async def request_id_middleware(request: Request, call_next):
        request_id = request.headers.get("x-request-id") or str(uuid4())
        request.state.request_id = request_id
        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        return response

    app.state.request_id_middleware_configured = True
