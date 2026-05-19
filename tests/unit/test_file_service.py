import asyncio
import io

import pytest
from fastapi import UploadFile

from app.core.exceptions import ValidationError
from app.services.file_service import FileService


def test_validate_pdf_accepts_pdf_bytes(test_settings, pdf_bytes):
    service = FileService(settings=test_settings)
    upload = UploadFile(filename="sample.pdf", file=io.BytesIO(pdf_bytes))

    payload = asyncio.run(service.validate_pdf(upload))

    assert payload == pdf_bytes


def test_validate_pdf_rejects_non_pdf(test_settings):
    service = FileService(settings=test_settings)
    upload = UploadFile(filename="sample.txt", file=io.BytesIO(b"hello"))

    with pytest.raises(ValidationError):
        asyncio.run(service.validate_pdf(upload))
