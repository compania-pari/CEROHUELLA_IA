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


@router.post(
    "/single",
    response_model=RequestResponse,
    summary="Anonimizar un PDF",
    description=(
        "Recibe un unico archivo PDF, registra la solicitud en la base de datos, "
        "anonimiza la informacion sensible usando Google Cloud DLP y devuelve el "
        "estado final de la solicitud junto con el detalle del archivo procesado. "
        "Este endpoint espera a que termine el procesamiento antes de responder."
    ),
    response_description="Solicitud registrada y procesada con el detalle del PDF anonimizado.",
)
async def create_single_redaction(
    file: UploadFile = File(...),
    service: RedactionService = Depends(get_redaction_service),
) -> RequestResponse:
    try:
        return await service.create_single_request(file)
    except ValidationError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.post(
    "/batch",
    response_model=BatchAcceptedResponse,
    status_code=202,
    summary="Registrar un lote de PDFs para anonimizar",
    description=(
        "Recibe varios archivos PDF en una sola solicitud, los valida, los almacena "
        "temporalmente en disco local, registra la auditoria en PostgreSQL y devuelve "
        "un identificador de solicitud. El procesamiento se ejecuta en segundo plano, "
        "por lo que la respuesta inicial no incluye aun los PDFs finales. Usa el "
        "endpoint de consulta por request_id para revisar el avance."
    ),
    response_description="Solicitud de lote aceptada para procesamiento asincrono.",
)
async def create_batch_redaction(
    background_tasks: BackgroundTasks,
    files: list[UploadFile] = File(...),
    service: RedactionService = Depends(get_redaction_service),
) -> BatchAcceptedResponse:
    try:
        return await service.create_batch_request(files, background_tasks)
    except ValidationError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.get(
    "/{request_id}",
    response_model=RequestResponse,
    summary="Consultar el estado de una solicitud",
    description=(
        "Devuelve la cabecera de auditoria de una solicitud de anonimizacion y el "
        "detalle de sus archivos. Es util para saber si una carga individual o un lote "
        "sigue pendiente, esta en proceso, termino correctamente o fallo. Para lotes, "
        "tambien muestra cuandos archivos fueron procesados, cuantos terminaron bien "
        "y cuantos fallaron."
    ),
    response_description="Estado de la solicitud y detalle de archivos asociados.",
)
def get_redaction_request(
    request_id: UUID,
    service: RedactionService = Depends(get_redaction_service),
) -> RequestResponse:
    try:
        return service.get_request(request_id)
    except NotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.get(
    "/{request_id}/files",
    response_model=list[RedactionFileResponse],
    summary="Listar archivos de una solicitud",
    description=(
        "Lista solo los archivos asociados a una solicitud de anonimizacion. "
        "Cada item incluye nombre original, nombre almacenado, estado del archivo, "
        "fechas de atencion, mensaje de error si existiera y la URL de descarga "
        "cuando el PDF anonimizado ya esta disponible."
    ),
    response_description="Lista de archivos registrados para la solicitud indicada.",
)
def list_redaction_files(
    request_id: UUID,
    service: RedactionService = Depends(get_redaction_service),
) -> list[RedactionFileResponse]:
    try:
        return service.list_request_files(request_id)
    except NotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.get(
    "/files/{file_id}/download",
    summary="Descargar un PDF anonimizado",
    description=(
        "Descarga el archivo PDF resultante de un item procesado. Este endpoint debe "
        "usarse con el file_id, no con el request_id. Si el archivo todavia no fue "
        "procesado o no existe fisicamente en el storage local, la API devolvera un "
        "error indicando que el resultado aun no esta disponible."
    ),
    response_description="Archivo PDF anonimizado.",
)
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
