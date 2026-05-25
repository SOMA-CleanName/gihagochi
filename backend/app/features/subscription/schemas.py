"""F-012 / F-013 subscription — Pydantic 스키마 (API 입출력)."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class SubscriptionDetail(BaseModel):
    """subscriptions 단건. POST/DELETE 응답 공통."""

    fan_id: UUID
    idol_id: UUID
    subscribed_at: datetime
    unsubscribed_at: datetime | None
    last_read_at: datetime
    is_active: bool  # unsubscribed_at IS NULL
