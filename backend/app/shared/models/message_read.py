# OWNER: chat_meta (F-021 읽음 처리)
"""message_reads — 팬별 메시지 읽음 기록. (message_id, fan_id) 복합 PK."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import DateTime, ForeignKey, text
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import Uuid

from app.core.db import Base


class MessageRead(Base):
    __tablename__ = "message_reads"

    message_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("messages.id", ondelete="CASCADE"), primary_key=True
    )
    fan_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("profiles.id", ondelete="CASCADE"), primary_key=True
    )
    read_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("NOW()")
    )
