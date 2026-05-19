import os

from app.core.config import Settings


def configure_google_application_credentials(settings: Settings) -> None:
    if os.getenv("GOOGLE_APPLICATION_CREDENTIALS"):
        return

    if not settings.google_application_credentials_json:
        return

    credentials_path = settings.google_application_credentials_path
    credentials_path.parent.mkdir(parents=True, exist_ok=True)
    credentials_path.write_text(settings.google_application_credentials_json, encoding="utf-8")
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = str(credentials_path)
