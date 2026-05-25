"""F-033 / F-037 report — Pydantic 스키마."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.shared.enums import ReportAction, ReportStatus


class ReportCreateRequest(BaseModel):
    """POST /reports 요청."""

    message_id: UUID
    reason: str = Field(min_length=10, max_length=500)


class ReportResolveRequest(BaseModel):
    """POST /admin/reports/{id}/resolve 요청."""

    resolution_action: ReportAction
    resolution_note: str | None = Field(default=None, max_length=500)


class ReportDetail(BaseModel):
    """reports 단건 응답."""

    id: UUID
    reporter_id: UUID
    message_id: UUID
    reason: str
    status: ReportStatus
    resolution_action: ReportAction | None
    resolution_note: str | None
    handled_by: UUID | None
    handled_at: datetime | None
    created_at: datetime


class ReportListPage(BaseModel):
    """GET /admin/reports 응답 (페이지)."""

    items: list[ReportDetail]
    page: int
    page_size: int
    has_more: bool
