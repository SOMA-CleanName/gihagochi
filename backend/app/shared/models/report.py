# OWNER: report (F-033 신고하기, F-037 관리자 처리)
"""reports — 메시지 신고 + 관리자 처리 이력."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import DateTime, ForeignKey, text
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import Uuid

from app.core.db import Base
from app.shared.enums import ReportAction, ReportStatus


class Report(Base):
    __tablename__ = "reports"

    id: Mapped[UUID] = mapped_column(
        Uuid, primary_key=True, server_default=text("gen_random_uuid()")
    )
    reporter_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("profiles.id", ondelete="RESTRICT"), nullable=False
    )
    message_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("messages.id", ondelete="RESTRICT"), nullable=False
    )
    reason: Mapped[str] = mapped_column(nullable=False)
    status: Mapped[ReportStatus] = mapped_column(
        SAEnum(ReportStatus, name="report_status", create_type=False),
        nullable=False,
        server_default=text("'pending'::report_status"),
    )
    resolution_action: Mapped[ReportAction | None] = mapped_column(
        SAEnum(ReportAction, name="report_action", create_type=False)
    )
    resolution_note: Mapped[str | None] = mapped_column()
    handled_by: Mapped[UUID | None] = mapped_column(
        Uuid, ForeignKey("profiles.id", ondelete="RESTRICT")
    )
    handled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("NOW()")
    )
