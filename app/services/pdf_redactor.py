from __future__ import annotations

from pathlib import Path

from pdf2image import convert_from_path
from PIL import Image

from app.core.config import Settings, get_settings
from app.core.exceptions import RedactionError


class PdfRedactor:
    def redact_pdf(self, input_path: str, output_path: str, tmp_dir: str) -> None:
        raise NotImplementedError


class GoogleCloudDlpPdfRedactor(PdfRedactor):
    def __init__(self, settings: Settings | None = None) -> None:
        self.settings = settings or get_settings()

    def _build_client(self):
        from google.cloud import dlp_v2

        return dlp_v2.DlpServiceClient()

    def redact_pdf(self, input_path: str, output_path: str, tmp_dir: str) -> None:
        client = self._build_client()
        image_paths = self._pdf_to_images(input_path, tmp_dir)
        if not image_paths:
            raise RedactionError("No pages were generated from the input PDF")

        redacted_paths = []
        for image_path in image_paths:
            redacted_path = Path(tmp_dir) / f"redacted_{Path(image_path).name}"
            self._redact_image_with_dlp(client, image_path, str(redacted_path))
            redacted_paths.append(str(redacted_path))

        self._images_to_pdf(redacted_paths, output_path)

    def _pdf_to_images(self, pdf_path: str, tmp_dir: str) -> list[str]:
        images = convert_from_path(pdf_path, dpi=300)
        image_paths: list[str] = []
        for index, image in enumerate(images, start=1):
            image_path = Path(tmp_dir) / f"page_{index}.png"
            image.save(image_path, "PNG")
            image_paths.append(str(image_path))
        return image_paths

    def _redact_image_with_dlp(self, client, image_path: str, output_path: str) -> None:
        with open(image_path, "rb") as file_pointer:
            image_bytes = file_pointer.read()

        info_types = [
            {"name": "EMAIL_ADDRESS"},
            {"name": "CREDIT_CARD_NUMBER"},
            {"name": "PERSON_NAME"},
            {"name": "PHONE_NUMBER"},
            {"name": "LOCATION"},
            {"name": "PASSPORT"},
            {"name": "MEDICAL_RECORD_NUMBER"},
            {"name": "FINANCIAL_ACCOUNT_NUMBER"},
            {"name": "PERU_DNI_NUMBER"},
        ]

        custom_info_types = [
            {"info_type": {"name": "PERU_PHONE"}, "regex": {"pattern": r"\b9\d{8}\b"}},
            {"info_type": {"name": "PERU_LICENSE"}, "regex": {"pattern": r"\b[A-Z0-9]{8}\b"}},
            {"info_type": {"name": "PERU_RUC"}, "regex": {"pattern": r"\b(10|15|16|17|20|21|22)\d{9}\b"}},
            {
                "info_type": {"name": "PERU_ADDRESS"},
                "regex": {
                    "pattern": r"\b(?:Calle|Av\.|Jr\.|Pasaje|Psj\.|Carretera)\s+[A-Za-z0-9\s]+(?:\s+\d+)?\b"
                },
            },
        ]

        image_redaction_configs = [{"info_type": {"name": item["name"]}} for item in info_types] + [
            {"info_type": {"name": "PERU_PHONE"}},
            {"info_type": {"name": "PERU_LICENSE"}},
            {"info_type": {"name": "PERU_RUC"}},
            {"info_type": {"name": "PERU_ADDRESS"}},
        ]

        request = {
            "parent": f"projects/{self.settings.google_cloud_project_id}",
            "byte_item": {"type_": "IMAGE_PNG", "data": image_bytes},
            "inspect_config": {"info_types": info_types, "custom_info_types": custom_info_types},
            "image_redaction_configs": image_redaction_configs,
        }

        try:
            response = client.redact_image(request=request)
        except Exception as exc:  # pragma: no cover - external dependency
            raise RedactionError(f"Google DLP redaction failed: {exc}") from exc

        Path(output_path).write_bytes(response.redacted_image)

    def _images_to_pdf(self, image_paths: list[str], output_pdf: str) -> None:
        images = [Image.open(path).convert("RGB") for path in image_paths]
        first, rest = images[0], images[1:]
        first.save(output_pdf, save_all=True, append_images=rest, resolution=300)

