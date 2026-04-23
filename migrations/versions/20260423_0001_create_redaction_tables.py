"""create redaction tables

Revision ID: 20260423_0001
Revises:
Create Date: 2026-04-23 13:00:00
"""

from alembic import op
import sqlalchemy as sa


revision = "20260423_0001"
down_revision = None
branch_labels = None
depends_on = None


request_type = sa.Enum("single", "batch", name="request_type")
processing_status = sa.Enum("PENDING", "PROCESSING", "COMPLETED", "FAILED", name="processing_status")


def upgrade() -> None:
    bind = op.get_bind()
    request_type.create(bind, checkfirst=True)
    processing_status.create(bind, checkfirst=True)

    op.create_table(
        "redaction_requests",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("request_type", request_type, nullable=False),
        sa.Column("status", processing_status, nullable=False),
        sa.Column("requested_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("total_files", sa.Integer(), nullable=False),
        sa.Column("processed_files", sa.Integer(), nullable=False),
        sa.Column("succeeded_files", sa.Integer(), nullable=False),
        sa.Column("failed_files", sa.Integer(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "redaction_files",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("request_id", sa.Uuid(), nullable=False),
        sa.Column("original_filename", sa.String(length=255), nullable=False),
        sa.Column("stored_filename", sa.String(length=255), nullable=False),
        sa.Column("input_path", sa.Text(), nullable=False),
        sa.Column("output_path", sa.Text(), nullable=True),
        sa.Column("status", processing_status, nullable=False),
        sa.Column("requested_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("error_message", sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(["request_id"], ["redaction_requests.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_redaction_files_request_id"), "redaction_files", ["request_id"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_redaction_files_request_id"), table_name="redaction_files")
    op.drop_table("redaction_files")
    op.drop_table("redaction_requests")
    bind = op.get_bind()
    processing_status.drop(bind, checkfirst=True)
    request_type.drop(bind, checkfirst=True)
