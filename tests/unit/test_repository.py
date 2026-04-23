from app.core.enums import ProcessingStatus, RequestType
from app.repositories.redaction_repository import RedactionRepository


def test_repository_tracks_request_counters(db_session):
    repository = RedactionRepository(db_session)
    request = repository.create_request(
        RequestType.BATCH,
        [
            {"original_filename": "a.pdf", "stored_filename": "stored_a.pdf", "input_path": "input/a.pdf"},
            {"original_filename": "b.pdf", "stored_filename": "stored_b.pdf", "input_path": "input/b.pdf"},
        ],
    )

    first_file, second_file = request.files
    repository.mark_request_processing(request.id)
    repository.mark_file_processing(first_file.id)
    repository.mark_file_completed(first_file.id, "output/a.pdf")
    repository.mark_file_processing(second_file.id)
    repository.mark_file_failed(second_file.id, "boom")

    updated = repository.get_request(request.id)

    assert updated.processed_files == 2
    assert updated.succeeded_files == 1
    assert updated.failed_files == 1
    assert updated.status == ProcessingStatus.FAILED

