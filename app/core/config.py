from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    app_name: str = Field(default="CeroHuella IA API", alias="APP_NAME")
    app_env: str = Field(default="dev", alias="APP_ENV")
    app_host: str = Field(default="0.0.0.0", alias="APP_HOST")
    app_port: int = Field(default=8000, alias="APP_PORT")
    database_url: str = Field(
        default="postgresql+psycopg://postgres:postgres@localhost:5432/cerohuella",
        alias="DATABASE_URL",
    )
    google_cloud_project_id: str = Field(default="dummy-project", alias="GOOGLE_CLOUD_PROJECT_ID")
    google_application_credentials_json: str | None = Field(
        default=None,
        alias="GOOGLE_APPLICATION_CREDENTIALS_JSON",
    )
    google_application_credentials_b64: str | None = Field(
        default=None,
        alias="GOOGLE_APPLICATION_CREDENTIALS_B64",
    )
    google_application_credentials_path: Path = Field(
        default=Path("/tmp/google-application-credentials.json"),
        alias="GOOGLE_APPLICATION_CREDENTIALS_PATH",
    )
    storage_root: Path = Field(default=Path("storage"), alias="STORAGE_ROOT")
    max_file_size_mb: int = Field(default=25, alias="MAX_FILE_SIZE_MB")
    max_batch_files: int = Field(default=10, alias="MAX_BATCH_FILES")
    applicationinsights_connection_string: str | None = Field(
        default=None,
        alias="APPLICATIONINSIGHTS_CONNECTION_STRING",
    )
    otel_service_name: str | None = Field(default=None, alias="OTEL_SERVICE_NAME")

    @property
    def max_file_size_bytes(self) -> int:
        return self.max_file_size_mb * 1024 * 1024


@lru_cache
def get_settings() -> Settings:
    return Settings()
