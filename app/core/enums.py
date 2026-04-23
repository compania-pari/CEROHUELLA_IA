from enum import Enum


class RequestType(str, Enum):
    SINGLE = "single"
    BATCH = "batch"


class ProcessingStatus(str, Enum):
    PENDING = "PENDING"
    PROCESSING = "PROCESSING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"

