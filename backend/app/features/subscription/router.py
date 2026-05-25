"""F-012 / F-013 subscription — FastAPI 라우터.

main.py가 자동 등록.
"""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import AuthedUser
from app.core.db import get_session
from app.features.subscription import service
from app.features.subscription.schemas import SubscriptionDetail

router = APIRouter(prefix="/idols", tags=["subscription"])


@router.post(
    "/{idol_id}/subscribe",
    response_model=SubscriptionDetail,
    status_code=200,
)
async def subscribe(
    idol_id: UUID,
    user: AuthedUser,
    session: Annotated[AsyncSession, Depends(get_session)],
) -> SubscriptionDetail:
    """응원 시작 (또는 재구독). 멱등."""
    return await service.subscribe(session, fan_id=user.id, idol_id=idol_id)


@router.delete(
    "/{idol_id}/subscribe",
    response_model=SubscriptionDetail,
    status_code=200,
)
async def unsubscribe(
    idol_id: UUID,
    user: AuthedUser,
    session: Annotated[AsyncSession, Depends(get_session)],
) -> SubscriptionDetail:
    """응원 취소. 멱등."""
    return await service.unsubscribe(session, fan_id=user.id, idol_id=idol_id)
