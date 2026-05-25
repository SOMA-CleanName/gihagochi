"""F-035 / F-036 / F-038 admin — FastAPI 라우터.

main.py가 자동 등록. 라우터는 얇게 — AdminUser 의존성 + service 호출만.

게이트 정책:
- 모든 엔드포인트 `AdminUser` 의존성 = role=admin + status=active 강제
- 어드민 웹의 SELECT(리스트/검색)는 본 라우터 미노출 — Server Component가 supabase 직결
"""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import AdminUser
from app.core.db import get_session
from app.features.admin import service
from app.features.admin.schemas import (
    IdolApplicationDetail,
    RejectApplicationRequest,
    SuspendUserRequest,
    UserDetail,
)

router = APIRouter(prefix="/admin", tags=["admin"])


# ============================================================
# F-035 아이돌 가입 신청 승인/반려
# ============================================================


@router.post(
    "/idol-applications/{application_id}/approve",
    response_model=IdolApplicationDetail,
    status_code=200,
)
async def approve_idol_application(
    application_id: UUID,
    admin: AdminUser,
    session: Annotated[AsyncSession, Depends(get_session)],
) -> IdolApplicationDetail:
    """아이돌 가입 신청 승인 — applications UPDATE + idol_profiles INSERT + profiles UPDATE."""
    return await service.approve_idol_application(session, application_id, admin.id)


@router.post(
    "/idol-applications/{application_id}/reject",
    response_model=IdolApplicationDetail,
    status_code=200,
)
async def reject_idol_application(
    application_id: UUID,
    req: RejectApplicationRequest,
    admin: AdminUser,
    session: Annotated[AsyncSession, Depends(get_session)],
) -> IdolApplicationDetail:
    """아이돌 가입 신청 반려 — rejection_reason 필수."""
    return await service.reject_idol_application(
        session, application_id, admin.id, req.rejection_reason
    )


# ============================================================
# F-038 사용자/아이돌 정지·해제
# ============================================================


@router.post(
    "/users/{user_id}/suspend",
    response_model=UserDetail,
    status_code=200,
)
async def suspend_user(
    user_id: UUID,
    req: SuspendUserRequest,
    admin: AdminUser,
    session: Annotated[AsyncSession, Depends(get_session)],
) -> UserDetail:
    """사용자 정지 — suspend_reason 필수. 자기 자신 정지 시도 시 400."""
    return await service.suspend_user(session, user_id, admin.id, req.suspend_reason)


@router.post(
    "/users/{user_id}/unsuspend",
    response_model=UserDetail,
    status_code=200,
)
async def unsuspend_user(
    user_id: UUID,
    admin: AdminUser,
    session: Annotated[AsyncSession, Depends(get_session)],
) -> UserDetail:
    """사용자 정지 해제 — status='active' 복귀."""
    _ = admin  # 의존성으로 권한 검증만 사용 (id는 unsuspend 로직에서 안 씀)
    return await service.unsuspend_user(session, user_id)
