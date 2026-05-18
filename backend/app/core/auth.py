"""JWT 인증 + 권한 가드.

핵심:
- `get_current_user`: FastAPI Depends. Supabase JWT 검증 + profiles 조회.
- `require_role(*roles)`: 역할 가드 팩토리. 허용된 role만 통과.
- 미리 정의된 Annotated 타입(`AdminUser`, `IdolUser`, `FanUser`)으로 라우터에서 즉시 사용.

사용 예:
    @router.get("/me")
    async def me(user: Annotated[CurrentUser, Depends(get_current_user)]):
        return {"id": user.id, "role": user.role}

    @router.post("/admin/users/{uid}/suspend")
    async def suspend(uid: UUID, admin: AdminUser):
        ...
"""

from collections.abc import Awaitable, Callable
from dataclasses import dataclass
from typing import Annotated
from uuid import UUID

import jwt
from fastapi import Depends, Header
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.db import get_session
from app.core.errors import ForbiddenError, UnauthorizedError
from app.shared.enums import UserRole, UserStatus
from app.shared.models.profile import Profile


@dataclass(slots=True, frozen=True)
class CurrentUser:
    """인증된 사용자 정보. 라우터/서비스에서 권한 분기 시 사용."""

    id: UUID
    role: UserRole
    status: UserStatus
    display_name: str


# ============================================================
# JWT 처리
# ============================================================


def _extract_bearer(authorization: str | None) -> str:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise UnauthorizedError("Authorization 헤더가 필요합니다 (Bearer <token>).")
    return authorization.split(" ", 1)[1].strip()


def _decode_jwt(token: str) -> dict:
    settings = get_settings()
    try:
        return jwt.decode(
            token,
            settings.supabase_jwt_secret,
            algorithms=["HS256"],
            audience="authenticated",
        )
    except jwt.ExpiredSignatureError as e:
        raise UnauthorizedError("토큰이 만료되었습니다.") from e
    except jwt.InvalidTokenError as e:
        raise UnauthorizedError(f"유효하지 않은 토큰: {e}") from e


# ============================================================
# 의존성
# ============================================================


async def get_current_user(
    session: Annotated[AsyncSession, Depends(get_session)],
    authorization: Annotated[str | None, Header()] = None,
) -> CurrentUser:
    """JWT 검증 + profiles 조회.

    실패:
    - 401 UnauthorizedError: 토큰 누락/만료/무효, 사용자 미등록
    - 403 ForbiddenError: 정지/탈퇴된 계정
    """
    token = _extract_bearer(authorization)
    payload = _decode_jwt(token)

    try:
        user_id = UUID(payload["sub"])
    except (KeyError, ValueError) as e:
        raise UnauthorizedError("토큰에 유효한 sub claim이 없습니다.") from e

    profile = await session.scalar(select(Profile).where(Profile.id == user_id))
    if profile is None:
        raise UnauthorizedError("등록되지 않은 사용자입니다.")
    if profile.deleted_at is not None:
        raise ForbiddenError("탈퇴된 계정입니다.")
    if profile.status == UserStatus.SUSPENDED:
        raise ForbiddenError("정지된 계정입니다.")

    return CurrentUser(
        id=profile.id,
        role=profile.role,
        status=profile.status,
        display_name=profile.display_name,
    )


def require_role(
    *allowed: UserRole,
) -> Callable[[CurrentUser], Awaitable[CurrentUser]]:
    """Depends 팩토리. 허용된 role만 통과.

    사용:
        @router.post("/admin/...")
        async def handler(
            user: Annotated[CurrentUser, Depends(require_role(UserRole.ADMIN))],
        ): ...
    """

    async def _check(
        user: Annotated[CurrentUser, Depends(get_current_user)],
    ) -> CurrentUser:
        if user.role not in allowed:
            raise ForbiddenError(f"필요한 권한: {', '.join(r.value for r in allowed)}")
        return user

    return _check


# ============================================================
# 미리 정의된 Annotated 타입 (자주 쓰는 케이스)
# ============================================================

AdminUser = Annotated[CurrentUser, Depends(require_role(UserRole.ADMIN))]
"""관리자만. F-035/F-037/F-038 등."""

IdolUser = Annotated[CurrentUser, Depends(require_role(UserRole.IDOL))]
"""아이돌만. F-025 메시지 발행, F-026 수정/삭제 등."""

FanUser = Annotated[CurrentUser, Depends(require_role(UserRole.FAN))]
"""팬만. F-012 응원, F-017 메시지 발신 등."""

AuthedUser = Annotated[CurrentUser, Depends(get_current_user)]
"""인증만 필요한 경우. 권한 분기 없음."""
