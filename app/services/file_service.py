from __future__ import annotations

import shutil
from pathlib import Path
from uuid import UUID, uuid4

from fastapi import UploadFile

from app.core.config import Settings, get_settings
from app.core.exceptions import StorageError, ValidationError


class FileService:
    def __init__(self, settings: Settings | None = None) -> None:
        self.settings = settings or get_settings()
        self.root = self.settings.storage_root

    def ensure_directories(self, request_id: UUID) -> dict[str, Path]:
        directories = {
            "input": self.root / "input" / str(request_id),
            "output": self.root / "output" / str(request_id),
            "tmp": self.root / "tmp" / str(request_id),
        }
        for path in directories.values():
            path.mkdir(parents=True, exist_ok=True)
        return directories

    async def validate_pdf(self, upload: UploadFile) -> bytes:
        payload = await upload.read()
        if not payload:
            raise ValidationError(f"The file {upload.filename or 'unknown'} is empty")
        if len(payload) > self.settings.max_file_size_bytes:
            raise ValidationError(f"The file {upload.filename or 'unknown'} exceeds the size limit")
        if not payload.startswith(b"%PDF"):
            raise ValidationError(f"The file {upload.filename or 'unknown'} is not a valid PDF")
        return payload

    def validate_batch_count(self, uploads: list[UploadFile]) -> None:
        if not uploads:
            raise ValidationError("At least one PDF file is required")
        if len(uploads) > self.settings.max_batch_files:
            raise ValidationError("The number of files exceeds the batch limit")

    def save_input_file(self, request_id: UUID, original_filename: str, payload: bytes) -> dict[str, str]:
        directories = self.ensure_directories(request_id)
        safe_name = Path(original_filename or "document.pdf").name
        stored_filename = f"{uuid4()}_{safe_name}"
        file_path = directories["input"] / stored_filename
        file_path.write_bytes(payload)
        return {
            "original_filename": safe_name,
            "stored_filename": stored_filename,
            "input_path": str(file_path),
        }

    def build_output_path(self, request_id: UUID, stored_filename: str) -> Path:
        directories = self.ensure_directories(request_id)
        output_name = f"redacted_{stored_filename}"
        return directories["output"] / output_name

    def get_tmp_dir(self, request_id: UUID) -> Path:
        return self.ensure_directories(request_id)["tmp"]

    def cleanup_tmp_dir(self, request_id: UUID) -> None:
        tmp_dir = self.root / "tmp" / str(request_id)
        if tmp_dir.exists():
            shutil.rmtree(tmp_dir)

    def ensure_output_exists(self, output_path: str | None) -> Path:
        if not output_path:
            raise StorageError("The file does not have an output PDF available")
        path = Path(output_path)
        if not path.exists():
            raise StorageError("The output PDF was not found on disk")
        return path

