from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict

from app.core.enums import ProcessingStatus, RequestType


class FileResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    original_filename: str
    stored_filename: str
    input_path: str
    output_path: str | None
    status: ProcessingStatus
    requested_at: datetime
    started_at: datetime | None
    completed_at: datetime | None
    error_message: str | None
    download_url: str | None = None


class RequestResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    request_type: RequestType
    status: ProcessingStatus
    requested_at: datetime
    started_at: datetime | None
    completed_at: datetime | None
    total_files: int
    processed_files: int
    succeeded_files: int
    failed_files: int
    files: list[FileResponse]


class BatchAcceptedResponse(BaseModel):
    request_id: UUID
    status: ProcessingStatus
    requested_at: datetime
    total_files: int

