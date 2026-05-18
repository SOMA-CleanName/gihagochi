# OWNER: notification (F-029 푸시)
"""device_tokens — FCM 토큰. 사용자당 N개 (기기마다 1개)."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import DateTime, ForeignKey, text
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import Uuid

from app.core.db import Base
from app.shared.enums import DevicePlatform


class DeviceToken(Base):
    __tablename__ = "device_tokens"

    id: Mapped[UUID] = mapped_column(
        Uuid, primary_key=True, server_default=text("gen_random_uuid()")
    )
    user_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False
    )
    platform: Mapped[DevicePlatform] = mapped_column(
        SAEnum(DevicePlatform, name="device_platform", create_type=False), nullable=False
    )
    token: Mapped[str] = mapped_column(nullable=False, unique=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("NOW()")
    )
    last_used_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("NOW()")
    )
