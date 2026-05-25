"""F-008 / F-009 / F-010 / F-011 idol_discovery — FastAPI 라우터.

main.py가 자동 등록. 라우터는 얇게 — Query 검증 + service 호출만.
"""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import AuthedUser
from app.core.db import get_session
from app.features.idol_discovery import service
from app.features.idol_discovery.schemas import IdolDetailResponse, IdolListResponse

router = APIRouter(prefix="/idols", tags=["idol_discovery"])


@router.get("", response_model=IdolListResponse)
async def list_idols(
    user: AuthedUser,
    session: Annotated[AsyncSession, Depends(get_session)],
    q: Annotated[str | None, Query(max_length=200)] = None,
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=50)] = 20,
) -> IdolListResponse:
    """활성 아이돌 리스트 (검색/페이지). 정렬은 activated_at DESC 고정."""
    _ = user  # 인증만 요구. 결과는 모두 동일.
    return await service.list_idols(session, q=q, page=page, page_size=page_size)


@router.get("/{idol_id}", response_model=IdolDetailResponse)
async def get_idol_detail(
    idol_id: UUID,
    user: AuthedUser,
    session: Annotated[AsyncSession, Depends(get_session)],
) -> IdolDetailResponse:
    """아이돌 상세 — 응원 팬 수 + 본인 응원 여부 포함."""
    return await service.get_idol_detail(session, idol_id, viewer_id=user.id)
