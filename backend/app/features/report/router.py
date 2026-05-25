"""F-033 / F-037 report — FastAPI 라우터.

main.py 자동 등록.
"""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import AdminUser, FanUser
from app.core.db import get_session
from app.features.report import service
from app.features.report.schemas import (
    ReportCreateRequest,
    ReportDetail,
    ReportListPage,
    ReportResolveRequest,
)

# 신고 생성은 /reports, 관리자 처리는 /admin/reports — 도메인 분리.
router = APIRouter(tags=["report"])


# ============================================================
# F-033 신고 생성 (팬)
# ============================================================


@router.post(
    "/reports",
    response_model=ReportDetail,
    status_code=status.HTTP_201_CREATED,
)
async def create_report(
    payload: ReportCreateRequest,
    user: FanUser,
    session: Annotated[AsyncSession, Depends(get_session)],
) -> ReportDetail:
    """신고 생성. 자기 메시지/중복/없는 메시지 차단."""
    return await service.create_report(
        session,
        reporter_id=user.id,
        message_id=payload.message_id,
        reason=payload.reason,
    )


# ============================================================
# F-037 관리자 — 큐 + 처리
# ============================================================


@router.get(
    "/admin/reports",
    response_model=ReportListPage,
)
async def list_pending_reports(
    user: AdminUser,  # noqa: ARG001 (인증 가드)
    session: Annotated[AsyncSession, Depends(get_session)],
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=50),
) -> ReportListPage:
    """대기 큐 조회 (status='pending' only, 오래된 순)."""
    return await service.list_pending_reports(session, page=page, page_size=page_size)


@router.post(
    "/admin/reports/{report_id}/resolve",
    response_model=ReportDetail,
)
async def resolve_report(
    report_id: UUID,
    payload: ReportResolveRequest,
    user: AdminUser,
    session: Annotated[AsyncSession, Depends(get_session)],
) -> ReportDetail:
    """신고 처리. status='handled' + resolution_action 기록. 멱등 X."""
    return await service.resolve_report(
        session,
        report_id=report_id,
        admin_user_id=user.id,
        request=payload,
    )
