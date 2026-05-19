import os

from app.core.config import Settings
from app.core.gcp_credentials import configure_google_application_credentials


def test_configure_google_credentials_writes_secret_json(tmp_path, monkeypatch):
    monkeypatch.delenv("GOOGLE_APPLICATION_CREDENTIALS", raising=False)
    credentials_path = tmp_path / "gcp.json"
    settings = Settings(
        APP_NAME="Test API",
        APP_ENV="test",
        DATABASE_URL="sqlite+pysqlite:///:memory:",
        GOOGLE_CLOUD_PROJECT_ID="test-project",
        GOOGLE_APPLICATION_CREDENTIALS_JSON='{"type":"service_account"}',
        GOOGLE_APPLICATION_CREDENTIALS_PATH=credentials_path,
    )

    configure_google_application_credentials(settings)

    assert credentials_path.read_text(encoding="utf-8") == '{"type":"service_account"}'
    assert os.environ["GOOGLE_APPLICATION_CREDENTIALS"] == str(credentials_path)


def test_configure_google_credentials_keeps_existing_path(tmp_path, monkeypatch):
    existing_path = tmp_path / "existing.json"
    monkeypatch.setenv("GOOGLE_APPLICATION_CREDENTIALS", str(existing_path))
    settings = Settings(
        APP_NAME="Test API",
        APP_ENV="test",
        DATABASE_URL="sqlite+pysqlite:///:memory:",
        GOOGLE_CLOUD_PROJECT_ID="test-project",
        GOOGLE_APPLICATION_CREDENTIALS_JSON='{"type":"service_account"}',
        GOOGLE_APPLICATION_CREDENTIALS_PATH=tmp_path / "new.json",
    )

    configure_google_application_credentials(settings)

    assert os.environ["GOOGLE_APPLICATION_CREDENTIALS"] == str(existing_path)
    assert not (tmp_path / "new.json").exists()
