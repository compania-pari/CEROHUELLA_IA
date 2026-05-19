from __future__ import annotations

from uuid import UUID, uuid4

from fastapi import BackgroundTasks, UploadFile
from sqlalchemy.orm import Session

from app.core.enums import ProcessingStatus, RequestType
from app.core.exceptions import RedactionError, StorageError, ValidationError
from app.db.session import SessionLocal
from app.repositories.redaction_repository import RedactionRepository
from app.schemas.redaction import BatchAcceptedResponse, FileResponse, RequestResponse
from app.services.file_service import FileService
from app.services.pdf_redactor import GoogleCloudDlpPdfRedactor, PdfRedactor


class RedactionService:
    def __init__(
        self,
        db: Session,
        file_service: FileService | None = None,
        pdf_redactor: PdfRedactor | None = None,
        session_factory=SessionLocal,
    ) -> None:
        self.db = db
        self.repository = RedactionRepository(db)
        self.file_service = file_service or FileService()
        self.pdf_redactor = pdf_redactor or GoogleCloudDlpPdfRedactor()
        self.session_factory = session_factory

    async def create_single_request(self, upload: UploadFile) -> RequestResponse:
        payload = await self.file_service.validate_pdf(upload)
        request_id = uuid4()
        file_payload = self.file_service.save_input_file(request_id, upload.filename or "document.pdf", payload)
        request = self.repository.create_request(RequestType.SINGLE, [file_payload], request_id=request_id)
        self.process_request(request.id)
        return self._to_request_response(self.repository.get_request(request.id))

    async def create_batch_request(
        self,
        uploads: list[UploadFile],
        background_tasks: BackgroundTasks,
    ) -> BatchAcceptedResponse:
        self.file_service.validate_batch_count(uploads)
        file_payloads: list[dict[str, str]] = []
        request_id = uuid4()

        for upload in uploads:
            payload = await self.file_service.validate_pdf(upload)
            file_payloads.append(
                self.file_service.save_input_file(request_id, upload.filename or "document.pdf", payload)
            )

        request = self.repository.create_request(RequestType.BATCH, file_payloads, request_id=request_id)
        background_tasks.add_task(self._process_request_in_new_session, request.id)
        return BatchAcceptedResponse(
            request_id=request.id,
            status=request.status,
            requested_at=request.requested_at,
            total_files=request.total_files,
        )

    def process_request(self, request_id: UUID) -> None:
        request = self.repository.get_request(request_id)
        self.repository.mark_request_processing(request_id)
        for file_record in request.files:
            self._process_file(file_record.id)

    def _process_file(self, file_id: UUID) -> None:
        file_record = self.repository.mark_file_processing(file_id)
        output_path = self.file_service.build_output_path(file_record.request_id, file_record.stored_filename)
        tmp_dir = self.file_service.get_tmp_dir(file_record.request_id)

        try:
            self.pdf_redactor.redact_pdf(file_record.input_path, str(output_path), str(tmp_dir))
            self.repository.mark_file_completed(file_record.id, str(output_path))
        except Exception as exc:
            message = str(exc) if isinstance(exc, (RedactionError, ValidationError, StorageError)) else f"Unhandled error: {exc}"
            self.repository.mark_file_failed(file_record.id, message)
        finally:
            self.file_service.cleanup_tmp_dir(file_record.request_id)

    def _process_request_in_new_session(self, request_id: UUID) -> None:
        db = self.session_factory()
        try:
            RedactionService(
                db=db,
                file_service=self.file_service,
                pdf_redactor=self.pdf_redactor,
                session_factory=self.session_factory,
            ).process_request(request_id)
        finally:
            db.close()

    def get_request(self, request_id: UUID) -> RequestResponse:
        request = self.repository.get_request(request_id)
        return self._to_request_response(request)

    def list_request_files(self, request_id: UUID) -> list[FileResponse]:
        request = self.repository.get_request(request_id)
        return [self._to_file_response(item) for item in request.files]

    def get_download_path(self, file_id: UUID) -> str:
        file_record = self.repository.get_file(file_id)
        output_path = self.file_service.ensure_output_exists(file_record.output_path)
        return str(output_path)

    def _to_request_response(self, request) -> RequestResponse:
        files = [self._to_file_response(item) for item in request.files]
        return RequestResponse(
            id=request.id,
            request_type=request.request_type,
            status=request.status,
            requested_at=request.requested_at,
            started_at=request.started_at,
            completed_at=request.completed_at,
            total_files=request.total_files,
            processed_files=request.processed_files,
            succeeded_files=request.succeeded_files,
            failed_files=request.failed_files,
            files=files,
        )

    def _to_file_response(self, file_record) -> FileResponse:
        download_url = None
        if file_record.status == ProcessingStatus.COMPLETED:
            download_url = f"/api/v1/redactions/files/{file_record.id}/download"
        return FileResponse(
            id=file_record.id,
            original_filename=file_record.original_filename,
            stored_filename=file_record.stored_filename,
            input_path=file_record.input_path,
            output_path=file_record.output_path,
            status=file_record.status,
            requested_at=file_record.requested_at,
            started_at=file_record.started_at,
            completed_at=file_record.completed_at,
            error_message=file_record.error_message,
            download_url=download_url,
        )
