# OWNER: notification (F-031 알림 설정)
"""notification_prefs — 사용자별 알림 on/off."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import DateTime, ForeignKey, text
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import Uuid

from app.core.db import Base


class NotificationPref(Base):
    __tablename__ = "notification_prefs"

    user_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("profiles.id", ondelete="CASCADE"), primary_key=True
    )
    new_message_enabled: Mapped[bool] = mapped_column(
        nullable=False, server_default=text("TRUE")
    )
    idol_reply_enabled: Mapped[bool] = mapped_column(
        nullable=False, server_default=text("TRUE")
    )
    marketing_enabled: Mapped[bool] = mapped_column(
        nullable=False, server_default=text("FALSE")
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("NOW()")
    )
