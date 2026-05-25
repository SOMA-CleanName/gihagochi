"""F-008 / F-009 / F-010 / F-011 idol_discovery — Pydantic 스키마 (API 입출력).

요청/응답 형태는 SPEC.md의 'API' 섹션과 1:1 매핑.
"""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class IdolListItem(BaseModel):
    """탐색 리스트 카드용 요약."""

    id: UUID
    stage_name: str
    bio_summary: str | None
    thumbnail_url: str | None
    activated_at: datetime


class IdolListResponse(BaseModel):
    """GET /idols 응답. offset/limit 기반 페이지네이션."""

    items: list[IdolListItem]
    page: int
    page_size: int
    has_more: bool


class IdolDetailResponse(BaseModel):
    """GET /idols/{idol_id} 응답. 응원 팬 수 + 본인 응원 여부 포함."""

    id: UUID
    stage_name: str
    bio: str | None
    thumbnail_url: str | None
    activated_at: datetime
    fan_count: int
    is_subscribed: bool
