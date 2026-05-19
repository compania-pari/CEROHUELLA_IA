import os
from base64 import b64decode
from json import JSONDecodeError, loads

from app.core.config import Settings


def configure_google_application_credentials(settings: Settings) -> None:
    if os.getenv("GOOGLE_APPLICATION_CREDENTIALS"):
        return

    credentials_json = _get_credentials_json(settings)
    if not credentials_json:
        return

    _validate_credentials_json(credentials_json)
    credentials_path = settings.google_application_credentials_path
    credentials_path.parent.mkdir(parents=True, exist_ok=True)
    credentials_path.write_text(credentials_json, encoding="utf-8")
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = str(credentials_path)


def _get_credentials_json(settings: Settings) -> str | None:
    if settings.google_application_credentials_b64:
        return b64decode(settings.google_application_credentials_b64).decode("utf-8")

    return settings.google_application_credentials_json


def _validate_credentials_json(credentials_json: str) -> None:
    try:
        loads(credentials_json)
    except JSONDecodeError as exc:
        raise ValueError("Google application credentials must be a valid JSON document.") from exc
