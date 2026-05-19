from uuid import uuid4

from app.core.enums import RequestType
from app.services.file_service import FileService
from app.services.redaction_service import RedactionService
from tests.conftest import FakePdfRedactor


def test_process_request_handles_partial_failures(db_session, test_settings):
    file_service = FileService(settings=test_settings)
    request_id = uuid4()
    payload_ok = file_service.save_input_file(request_id, "ok.pdf", b"%PDF-ok")
    payload_fail = file_service.save_input_file(request_id, "fail.pdf", b"%PDF-fail")

    service = RedactionService(
        db=db_session,
        file_service=file_service,
        pdf_redactor=FakePdfRedactor(should_fail_for={payload_fail["stored_filename"]}),
        session_factory=lambda: db_session,
    )
    request = service.repository.create_request(RequestType.BATCH, [payload_ok, payload_fail], request_id=request_id)

    service.process_request(request.id)
    updated = service.repository.get_request(request.id)

    assert updated.processed_files == 2
    assert updated.failed_files == 1
    assert updated.succeeded_files == 1
