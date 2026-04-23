from uuid import UUID

from fastapi import APIRouter, BackgroundTasks, Depends, File, HTTPException, UploadFile
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from app.core.exceptions import NotFoundError, StorageError, ValidationError
from app.db.session import get_db
from app.schemas.redaction import BatchAcceptedResponse, FileResponse as RedactionFileResponse, RequestResponse
from app.services.redaction_service import RedactionService


router = APIRouter(prefix="/redactions", tags=["redactions"])


def get_redaction_service(db: Session = Depends(get_db)) -> RedactionService:
    return RedactionService(db=db)


@router.post("/single", response_model=RequestResponse)
async def create_single_redaction(
    file: UploadFile = File(...),
    service: RedactionService = Depends(get_redaction_service),
) -> RequestResponse:
    try:
        return await service.create_single_request(file)
    except ValidationError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.post("/batch", response_model=BatchAcceptedResponse, status_code=202)
async def create_batch_redaction(
    background_tasks: BackgroundTasks,
    files: list[UploadFile] = File(...),
    service: RedactionService = Depends(get_redaction_service),
) -> BatchAcceptedResponse:
    try:
        return await service.create_batch_request(files, background_tasks)
    except ValidationError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.get("/{request_id}", response_model=RequestResponse)
def get_redaction_request(
    request_id: UUID,
    service: RedactionService = Depends(get_redaction_service),
) -> RequestResponse:
    try:
        return service.get_request(request_id)
    except NotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.get("/{request_id}/files", response_model=list[RedactionFileResponse])
def list_redaction_files(
    request_id: UUID,
    service: RedactionService = Depends(get_redaction_service),
) -> list[RedactionFileResponse]:
    try:
        return service.list_request_files(request_id)
    except NotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.get("/files/{file_id}/download")
def download_redacted_file(
    file_id: UUID,
    service: RedactionService = Depends(get_redaction_service),
):
    try:
        output_path = service.get_download_path(file_id)
    except NotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except StorageError as exc:
        raise HTTPException(status_code=409, detail=str(exc)) from exc
    return FileResponse(output_path, media_type="application/pdf", filename="redacted.pdf")

