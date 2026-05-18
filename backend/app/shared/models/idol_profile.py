# OWNER: auth (승인 시 생성, F-035), profile (편집, F-030) — 공동
"""idol_profiles — 활성화된 아이돌의 공개 프로필."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import DateTime, ForeignKey, text
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import Uuid

from app.core.db import Base


class IdolProfile(Base):
    __tablename__ = "idol_profiles"

    id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("profiles.id", ondelete="CASCADE"), primary_key=True
    )
    signup_application_id: Mapped[UUID] = mapped_column(
        Uuid,
        ForeignKey("idol_signup_applications.id", ondelete="RESTRICT"),
        nullable=False,
    )
    stage_name: Mapped[str] = mapped_column(nullable=False, unique=True)
    bio: Mapped[str | None] = mapped_column()
    thumbnail_url: Mapped[str | None] = mapped_column()
    activated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("NOW()")
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("NOW()")
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("NOW()")
    )
