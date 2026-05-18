# OWNER: auth (가입/탈퇴), admin (정지/해제)
"""profiles 테이블 — 모든 사용자(팬/아이돌/관리자).

`auth.users`와 1:1 (id 공유). Supabase가 인증 자체는 관리하고, 우리는 role/status/표시이름.
"""

from datetime import datetime
from uuid import UUID

from sqlalchemy import DateTime, text
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import Uuid

from app.core.db import Base
from app.shared.enums import UserRole, UserStatus


class Profile(Base):
    __tablename__ = "profiles"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True)
    role: Mapped[UserRole] = mapped_column(
        SAEnum(UserRole, name="user_role", create_type=False),
        nullable=False,
        server_default=text("'fan'::user_role"),
    )
    status: Mapped[UserStatus] = mapped_column(
        SAEnum(UserStatus, name="user_status", create_type=False),
        nullable=False,
        server_default=text("'pending'::user_status"),
    )
    display_name: Mapped[str] = mapped_column(nullable=False)
    avatar_url: Mapped[str | None] = mapped_column()
    suspended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    suspend_reason: Mapped[str | None] = mapped_column()
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("NOW()")
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("NOW()")
    )
