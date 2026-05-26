"""F-XXX 기능명 — 라우터.

main.py가 자동 등록 (단, `_template`은 폴더명 `_` 시작으로 스킵).
복사 후 활성화하려면 폴더명 변경 (예: `_template` → `auth`).
"""

from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import AuthedUser
from app.core.db import get_session
from app.features._template import service
from app.features._template.schemas import ExampleResponse

router = APIRouter(prefix="/template", tags=["template"])


@router.get("/me", response_model=ExampleResponse)
async def example_endpoint(
    user: AuthedUser,
    session: Annotated[AsyncSession, Depends(get_session)],
) -> ExampleResponse:
    """예시 — 인증된 사용자 자신의 프로필 정보 반환."""
    return await service.get_example(session, user.id)
