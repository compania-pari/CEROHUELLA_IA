import io


def test_single_redaction_flow(client, pdf_bytes):
    response = client.post(
        "/api/v1/redactions/single",
        files={"file": ("one.pdf", io.BytesIO(pdf_bytes), "application/pdf")},
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["request_type"] == "single"
    assert payload["status"] == "COMPLETED"
    assert payload["total_files"] == 1
    assert payload["files"][0]["download_url"]


def test_batch_redaction_flow(client, pdf_bytes):
    response = client.post(
        "/api/v1/redactions/batch",
        files=[
            ("files", ("one.pdf", io.BytesIO(pdf_bytes), "application/pdf")),
            ("files", ("two.pdf", io.BytesIO(pdf_bytes), "application/pdf")),
        ],
    )

    assert response.status_code == 202
    request_id = response.json()["request_id"]

    status_response = client.get(f"/api/v1/redactions/{request_id}")
    assert status_response.status_code == 200
    payload = status_response.json()
    assert payload["total_files"] == 2
    assert payload["processed_files"] == 2

    file_id = payload["files"][0]["id"]
    download_response = client.get(f"/api/v1/redactions/files/{file_id}/download")
    assert download_response.status_code == 200
    assert download_response.headers["content-type"].startswith("application/pdf")


def test_batch_rejects_non_pdf(client):
    response = client.post(
        "/api/v1/redactions/batch",
        files=[("files", ("bad.txt", io.BytesIO(b"hello"), "text/plain"))],
    )

    assert response.status_code == 400
