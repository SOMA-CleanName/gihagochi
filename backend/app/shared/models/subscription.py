# OWNER: subscription (F-012 응원 시작, F-013 응원 취소)
"""subscriptions — 팬↔아이돌 응원 관계. (fan_id, idol_id) 복합 PK."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import DateTime, ForeignKey, text
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import Uuid

from app.core.db import Base


class Subscription(Base):
    __tablename__ = "subscriptions"

    fan_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("profiles.id", ondelete="CASCADE"), primary_key=True
    )
    idol_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("profiles.id", ondelete="CASCADE"), primary_key=True
    )
    subscribed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("NOW()")
    )
    unsubscribed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    last_read_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("NOW()")
    )
