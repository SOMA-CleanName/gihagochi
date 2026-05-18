# OWNER: chat_message (F-017, F-018, F-022, F-025, F-026)
"""messages — 모든 채팅 메시지. type으로 3종 분기.

- idol_to_fans: 아이돌이 채팅방 전체 broadcast
- fan_to_idol: 팬이 아이돌에게 개인 (다른 팬 비공개)
- idol_reply: 아이돌이 팬 메시지에 답장 (전체 공개)

CHECK 제약은 DB가 보장. 모델은 컬럼 구조만.
"""

from datetime import datetime
from uuid import UUID

from sqlalchemy import DateTime, ForeignKey, text
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.types import Uuid

from app.core.db import Base
from app.shared.enums import MediaType, MessageType


class Message(Base):
    __tablename__ = "messages"

    id: Mapped[UUID] = mapped_column(
        Uuid, primary_key=True, server_default=text("gen_random_uuid()")
    )
    # 멱등성용 클라 생성 ID. (sender_id, client_message_id) unique partial index.
    client_message_id: Mapped[UUID | None] = mapped_column(Uuid)
    type: Mapped[MessageType] = mapped_column(
        SAEnum(MessageType, name="message_type", create_type=False), nullable=False
    )
    sender_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("profiles.id", ondelete="RESTRICT"), nullable=False
    )
    # 채팅방 owner. RLS 검증을 1단계로 끝내기 위해 비정규화로 보유.
    idol_id: Mapped[UUID] = mapped_column(
        Uuid, ForeignKey("profiles.id", ondelete="RESTRICT"), nullable=False
    )
    recipient_id: Mapped[UUID | None] = mapped_column(
        Uuid, ForeignKey("profiles.id", ondelete="RESTRICT")
    )
    parent_message_id: Mapped[UUID | None] = mapped_column(
        Uuid, ForeignKey("messages.id", ondelete="SET NULL")
    )
    content: Mapped[str | None] = mapped_column()
    media_type: Mapped[MediaType] = mapped_column(
        SAEnum(MediaType, name="media_type", create_type=False),
        nullable=False,
        server_default=text("'text'::media_type"),
    )
    media_url: Mapped[str | None] = mapped_column()
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("NOW()")
    )
    edited_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
