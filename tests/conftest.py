from collections.abc import Generator
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.api.v1.redactions import get_redaction_service
from app.core.config import Settings
from app.db.base import Base
from app.main import app
from app.services.file_service import FileService
from app.services.redaction_service import RedactionService


class FakePdfRedactor:
    def __init__(self, should_fail_for: set[str] | None = None) -> None:
        self.should_fail_for = should_fail_for or set()

    def redact_pdf(self, input_path: str, output_path: str, tmp_dir: str) -> None:
        input_name = Path(input_path).name
        if input_name in self.should_fail_for:
            raise RuntimeError("Synthetic redaction failure")
        Path(tmp_dir).mkdir(parents=True, exist_ok=True)
        Path(output_path).write_bytes(Path(input_path).read_bytes())


@pytest.fixture()
def test_settings(tmp_path: Path) -> Settings:
    return Settings(
        APP_NAME="Test API",
        APP_ENV="test",
        DATABASE_URL=f"sqlite+pysqlite:///{(tmp_path / 'test.db').as_posix()}",
        GOOGLE_CLOUD_PROJECT_ID="test-project",
        STORAGE_ROOT=tmp_path / "storage",
        MAX_FILE_SIZE_MB=5,
        MAX_BATCH_FILES=3,
    )


@pytest.fixture()
def session_factory(test_settings: Settings):
    engine = create_engine(
        test_settings.database_url,
        future=True,
        connect_args={"check_same_thread": False},
    )
    TestingSessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, expire_on_commit=False)
    Base.metadata.create_all(bind=engine)
    try:
        yield TestingSessionLocal
    finally:
        Base.metadata.drop_all(bind=engine)
        engine.dispose()


@pytest.fixture()
def db_session(session_factory) -> Generator[Session, None, None]:
    session = session_factory()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture()
def client(session_factory, test_settings: Settings) -> Generator[TestClient, None, None]:
    file_service = FileService(settings=test_settings)
    redactor = FakePdfRedactor()

    def override_service():
        db = session_factory()
        try:
            yield RedactionService(
                db=db,
                file_service=file_service,
                pdf_redactor=redactor,
                session_factory=session_factory,
            )
        finally:
            db.close()

    app.dependency_overrides[get_redaction_service] = override_service
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture()
def pdf_bytes() -> bytes:
    return b"%PDF-1.4\n1 0 obj\n<<>>\nendobj\ntrailer\n<<>>\n%%EOF"
