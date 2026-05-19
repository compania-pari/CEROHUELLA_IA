from __future__ import annotations

from datetime import datetime, timezone
from uuid import UUID, uuid4

from sqlalchemy.orm import Session, joinedload

from app.core.enums import ProcessingStatus, RequestType
from app.core.exceptions import NotFoundError
from app.models.redaction import RedactionFile, RedactionRequest


class RedactionRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def create_request(
        self,
        request_type: RequestType,
        files_payload: list[dict[str, str]],
        request_id: UUID | None = None,
    ) -> RedactionRequest:
        request = RedactionRequest(
            id=request_id or uuid4(),
            request_type=request_type,
            status=ProcessingStatus.PENDING,
            total_files=len(files_payload),
            processed_files=0,
            succeeded_files=0,
            failed_files=0,
        )
        self.db.add(request)
        self.db.flush()

        for payload in files_payload:
            self.db.add(
                RedactionFile(
                    request_id=request.id,
                    original_filename=payload["original_filename"],
                    stored_filename=payload["stored_filename"],
                    input_path=payload["input_path"],
                    status=ProcessingStatus.PENDING,
                )
            )

        self.db.commit()
        return self.get_request(request.id)

    def get_request(self, request_id: UUID) -> RedactionRequest:
        request = (
            self.db.query(RedactionRequest)
            .options(joinedload(RedactionRequest.files))
            .filter(RedactionRequest.id == request_id)
            .first()
        )
        if request is None:
            raise NotFoundError(f"Request {request_id} not found")
        return request

    def get_file(self, file_id: UUID) -> RedactionFile:
        file_record = self.db.query(RedactionFile).filter(RedactionFile.id == file_id).first()
        if file_record is None:
            raise NotFoundError(f"File {file_id} not found")
        return file_record

    def mark_request_processing(self, request_id: UUID) -> None:
        request = self.get_request(request_id)
        if request.started_at is None:
            request.started_at = datetime.now(timezone.utc)
        request.status = ProcessingStatus.PROCESSING
        self.db.commit()

    def mark_file_processing(self, file_id: UUID) -> RedactionFile:
        file_record = self.get_file(file_id)
        if file_record.started_at is None:
            file_record.started_at = datetime.now(timezone.utc)
        file_record.status = ProcessingStatus.PROCESSING
        self.db.commit()
        self.db.refresh(file_record)
        return file_record

    def mark_file_completed(self, file_id: UUID, output_path: str) -> None:
        file_record = self.get_file(file_id)
        file_record.status = ProcessingStatus.COMPLETED
        file_record.output_path = output_path
        file_record.completed_at = datetime.now(timezone.utc)
        file_record.error_message = None
        self.db.commit()
        self._refresh_request_counters(file_record.request_id)

    def mark_file_failed(self, file_id: UUID, error_message: str) -> None:
        file_record = self.get_file(file_id)
        file_record.status = ProcessingStatus.FAILED
        file_record.completed_at = datetime.now(timezone.utc)
        file_record.error_message = error_message
        self.db.commit()
        self._refresh_request_counters(file_record.request_id)

    def _refresh_request_counters(self, request_id: UUID) -> None:
        request = self.get_request(request_id)
        processed = sum(1 for item in request.files if item.status in {ProcessingStatus.COMPLETED, ProcessingStatus.FAILED})
        succeeded = sum(1 for item in request.files if item.status == ProcessingStatus.COMPLETED)
        failed = sum(1 for item in request.files if item.status == ProcessingStatus.FAILED)

        request.processed_files = processed
        request.succeeded_files = succeeded
        request.failed_files = failed

        if processed == 0:
            request.status = ProcessingStatus.PENDING
        elif processed < request.total_files:
            request.status = ProcessingStatus.PROCESSING
        elif failed == request.total_files:
            request.status = ProcessingStatus.FAILED
            request.completed_at = datetime.now(timezone.utc)
        else:
            request.status = ProcessingStatus.COMPLETED if failed == 0 else ProcessingStatus.FAILED
            request.completed_at = datetime.now(timezone.utc)

        self.db.commit()
