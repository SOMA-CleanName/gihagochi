"""F-042/F-043 character — 라우터.

main.py가 자동 등록.
"""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import AuthedUser
from app.core.db import get_session
from app.features.character import service
from app.features.character.schemas import (
    ActionRequest,
    ActionResponse,
    CharacterStateResponse,
)

router = APIRouter(prefix="/character", tags=["character"])


@router.get("/{idol_id}/state", response_model=CharacterStateResponse)
async def get_character_state(
    idol_id: UUID,
    session: Annotated[AsyncSession, Depends(get_session)],
) -> CharacterStateResponse:
    """캐릭터 현재 상태 — 비인증 OK (활성 아이돌 캐릭터는 공개).

    row 없으면 default(idle, 100/100/100) 응답.
    """
    return await service.get_state(session, idol_id)


@router.post("/{idol_id}/actions", response_model=ActionResponse, status_code=201)
async def trigger_character_action(
    idol_id: UUID,
    req: ActionRequest,
    user: AuthedUser,
    session: Annotated[AsyncSession, Depends(get_session)],
) -> ActionResponse:
    """캐릭터 행동 트리거. action_log INSERT + state.current_action 업데이트.

    인증된 사용자가 performed_by. 비즈니스 룰 (팬 vs 아이돌 권한 차이)은 후속 PR.
    """
    return await service.record_action(session, idol_id, req.action, user.id)
