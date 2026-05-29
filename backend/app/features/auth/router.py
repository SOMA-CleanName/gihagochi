"""F-001~F-006 auth — FastAPI 라우터.

main.py가 자동 등록. 라우터는 얇게 — 의존성 주입 + service 호출만.
"""

from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import AuthedUser, PendingAuthUser
from app.core.db import get_session
from app.features.auth import service
from app.features.auth.schemas import (
    MeResponse,
    ReagreeRequest,
    SignupRequest,
    SignupResponse,
    TermsCurrentResponse,
)

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/signup", response_model=SignupResponse, status_code=200)
async def signup(
    req: SignupRequest,
    supabase_user_id: PendingAuthUser,
    session: Annotated[AsyncSession, Depends(get_session)],
) -> SignupResponse:
    """소셜 OAuth 직후 호출. profile + (선택)아이돌 신청 + 약관 동의를 한 번에 생성.

    인증: PendingAuthUser — JWT만 검증, profile 없어도 통과.
    """
    return await service.create_signup(session, supabase_user_id, req)


@router.get("/me", response_model=MeResponse)
async def me(
    user: AuthedUser,
    session: Annotated[AsyncSession, Depends(get_session)],
) -> MeResponse:
    """현재 사용자 프로필 + 최신 아이돌 신청 상태."""
    return await service.get_me(session, user.id)


@router.post("/logout", status_code=204)
async def logout(user: AuthedUser) -> None:
    """서버측은 별도 작업 없음 (Supabase가 세션 관리). 호출 로깅 + 204 No Content.

    실제 토큰 무효화는 클라이언트의 supabase.auth.signOut()이 처리.
    """
    # 인증된 사용자라는 사실 자체로 로깅용 — 명시적 작업은 없음.
    _ = user
    return None


@router.get("/terms/current", response_model=TermsCurrentResponse)
async def terms_current() -> TermsCurrentResponse:
    """현재 활성 약관 version 목록. 가입 화면이 호출. 비인증."""
    return service.get_current_terms()


@router.post("/terms/reagree", status_code=204)
async def terms_reagree(
    req: ReagreeRequest,
    user: AuthedUser,
    session: Annotated[AsyncSession, Depends(get_session)],
) -> None:
    """약관 재동의. /auth/me의 needs_reagree가 비어있지 않을 때 모달에서 호출.

    성공 시 204 No Content. version mismatch면 422.
    """
    await service.reagree(session, user.id, req)
    return None
