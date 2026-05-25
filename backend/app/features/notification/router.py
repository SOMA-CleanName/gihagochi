"""F-029 / F-031 notification — FastAPI 라우터.

main.py 자동 등록.
"""

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import AuthedUser
from app.core.db import get_session
from app.features.notification import service
from app.features.notification.schemas import (
    DeviceTokenRegisterRequest,
    DeviceTokenResponse,
    NotificationPrefsPatchRequest,
    NotificationPrefsResponse,
)

router = APIRouter(prefix="/notification", tags=["notification"])


# ============================================================
# device_tokens
# ============================================================


@router.post(
    "/device-tokens",
    response_model=DeviceTokenResponse,
    status_code=status.HTTP_200_OK,
)
async def register_device_token(
    payload: DeviceTokenRegisterRequest,
    user: AuthedUser,
    session: Annotated[AsyncSession, Depends(get_session)],
) -> DeviceTokenResponse:
    """FCM 토큰 등록 (멱등, reassign)."""
    return await service.register_device_token(
        session,
        user_id=user.id,
        token=payload.token,
        platform=payload.platform,
    )


@router.delete(
    "/device-tokens",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def unregister_device_token(
    user: AuthedUser,
    session: Annotated[AsyncSession, Depends(get_session)],
    # path 인코딩 회피 위해 query 채택 (FCM 토큰에 `/`, `:` 포함 가능).
    token: str = Query(..., min_length=1, max_length=4096),
) -> None:
    """본인 FCM 토큰 해제. 멱등."""
    await service.unregister_device_token(session, user_id=user.id, token=token)


# ============================================================
# notification_prefs
# ============================================================


@router.get(
    "/prefs",
    response_model=NotificationPrefsResponse,
)
async def get_prefs(
    user: AuthedUser,
    session: Annotated[AsyncSession, Depends(get_session)],
) -> NotificationPrefsResponse:
    """알림 설정 조회. row 없으면 default 생성 후 반환."""
    return await service.get_or_create_prefs(session, user_id=user.id)


@router.patch(
    "/prefs",
    response_model=NotificationPrefsResponse,
)
async def patch_prefs(
    payload: NotificationPrefsPatchRequest,
    user: AuthedUser,
    session: Annotated[AsyncSession, Depends(get_session)],
) -> NotificationPrefsResponse:
    """알림 설정 부분 수정. 1개 이상 필드 필수 (스키마 validator)."""
    return await service.update_prefs(session, user_id=user.id, patch=payload)
