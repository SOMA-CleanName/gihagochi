# OWNER: auth (F-002 아이돌 가입 신청), admin (F-035 승인/반려)
"""idol_signup_applications — 아이돌 가입 신청 + 관리자 처리 이력."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import DateTime, ForeignKey, text
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import Uuid

from app.core.db import Base
from app.shared.enums import SignupApplicationStatus


class IdolSignupApplication(Base):
    __tablename__ = "idol_signup_applications"

    id: Mapped[UUID] = mapped_column(
        Uuid, primary_key=True, server_default=text("gen_random_uuid()")
    )
    user_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("profiles.id", ondelete="RESTRICT"), nullable=False
    )
    stage_name: Mapped[str] = mapped_column(nullable=False)
    bio: Mapped[str | None] = mapped_column()
    application_note: Mapped[str | None] = mapped_column()
    status: Mapped[SignupApplicationStatus] = mapped_column(
        SAEnum(
            SignupApplicationStatus,
            name="signup_application_status",
            create_type=False,
            values_callable=lambda e: [m.value for m in e],
        ),
        nullable=False,
        server_default=text("'pending'::signup_application_status"),
    )
    handled_by: Mapped[UUID | None] = mapped_column(
        Uuid, ForeignKey("profiles.id", ondelete="RESTRICT")
    )
    handled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    rejection_reason: Mapped[str | None] = mapped_column()
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("NOW()")
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("NOW()")
    )
