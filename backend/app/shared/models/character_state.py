# OWNER: character (F-042 캐릭터 상태)
"""character_states — 아이돌별 캐릭터 현재 상태 (1:1).

(idol_id) unique. 시간 경과/팬 행동/아이돌 트리거에 따라 변화.
"""

from datetime import datetime
from uuid import UUID

from sqlalchemy import DateTime, Float, ForeignKey, SmallInteger, text
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import Uuid

from app.core.db import Base
from app.shared.enums import CharacterActionType


class CharacterState(Base):
    __tablename__ = "character_states"

    id: Mapped[UUID] = mapped_column(
        Uuid, primary_key=True, server_default=text("gen_random_uuid()")
    )
    idol_id: Mapped[UUID] = mapped_column(
        Uuid,
        ForeignKey("profiles.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
    )
    current_action: Mapped[CharacterActionType] = mapped_column(
        SAEnum(
            CharacterActionType,
            name="character_action_type",
            create_type=False,
            values_callable=lambda e: [m.value for m in e],
        ),
        nullable=False,
        server_default="idle",
    )
    # 상태 수치 0-100. lazy 계산 우세 — read 시 시간 경과 반영.
    hunger: Mapped[int] = mapped_column(SmallInteger, nullable=False, server_default="100")
    happiness: Mapped[int] = mapped_column(SmallInteger, nullable=False, server_default="100")
    energy: Mapped[int] = mapped_column(SmallInteger, nullable=False, server_default="100")
    # PR-G2 드래그 위치 영속화 — flame world 좌표(logical). null = 미설정(모바일이 기본 위치 사용).
    position_x: Mapped[float | None] = mapped_column(Float, nullable=True)
    position_y: Mapped[float | None] = mapped_column(Float, nullable=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("NOW()"),
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("NOW()"),
    )
