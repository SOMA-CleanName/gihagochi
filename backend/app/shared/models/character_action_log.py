# OWNER: character (F-043 행동 트리거 로그)
"""character_action_logs — 캐릭터에 가해진 행동 이력.

각 row = 한 번의 행동 트리거. 팬(선물/탭) / 아이돌(직접 트리거) / 관리자 / 시스템(시간) 등.
"""

from datetime import datetime
from uuid import UUID

from sqlalchemy import DateTime, ForeignKey, text
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import Uuid

from app.core.db import Base
from app.shared.enums import CharacterActionType


class CharacterActionLog(Base):
    __tablename__ = "character_action_logs"

    id: Mapped[UUID] = mapped_column(
        Uuid, primary_key=True, server_default=text("gen_random_uuid()")
    )
    idol_id: Mapped[UUID] = mapped_column(
        Uuid,
        ForeignKey("profiles.id", ondelete="CASCADE"),
        nullable=False,
    )
    action: Mapped[CharacterActionType] = mapped_column(
        SAEnum(
            CharacterActionType,
            name="character_action_type",
            create_type=False,
            values_callable=lambda e: [m.value for m in e],
        ),
        nullable=False,
    )
    # NULL = 시스템 트리거 (시간 경과 등). 그 외 user_id (팬/아이돌/관리자).
    performed_by: Mapped[UUID | None] = mapped_column(
        Uuid,
        ForeignKey("profiles.id", ondelete="SET NULL"),
        nullable=True,
    )
    performed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("NOW()"),
    )
