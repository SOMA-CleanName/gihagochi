"""F-042/F-043 character — 서비스 레이어.

공개 인터페이스 (다른 피처가 호출 가능):
- `get_state(session, idol_id)` — 캐릭터 현재 상태 조회 (row 없으면 default)
- `record_action(session, idol_id, action, performed_by)` — 행동 로그 + state 업데이트
"""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError
from app.features.character.schemas import (
    ActionLogSummary,
    ActionResponse,
    CharacterStateResponse,
)
from app.shared.enums import CharacterActionType
from app.shared.models import CharacterActionLog, CharacterState, Profile

# 기본 상태 값 — DB row 없을 때 응답에 사용.
_DEFAULT_HUNGER = 100
_DEFAULT_HAPPINESS = 100
_DEFAULT_ENERGY = 100


async def get_state(session: AsyncSession, idol_id: UUID) -> CharacterStateResponse:
    """캐릭터 현재 상태. row 없으면 default 응답 (DB INSERT 없음).

    아이돌 존재 자체는 검증 — 없으면 404.
    """
    profile = await session.scalar(select(Profile).where(Profile.id == idol_id))
    if profile is None:
        raise NotFoundError("아이돌을 찾을 수 없습니다.")

    state = await session.scalar(select(CharacterState).where(CharacterState.idol_id == idol_id))
    if state is None:
        from datetime import UTC, datetime

        return CharacterStateResponse(
            idol_id=idol_id,
            current_action=CharacterActionType.IDLE,
            hunger=_DEFAULT_HUNGER,
            happiness=_DEFAULT_HAPPINESS,
            energy=_DEFAULT_ENERGY,
            position_x=None,
            position_y=None,
            furniture_layout=None,
            updated_at=datetime.now(UTC),
        )
    return _to_state_response(state)


async def record_action(
    session: AsyncSession,
    idol_id: UUID,
    action: CharacterActionType,
    performed_by: UUID | None,
) -> ActionResponse:
    """행동 트리거. action_log INSERT + state.current_action 업데이트.

    state row 없으면 default 값으로 새로 INSERT.
    performed_by=None은 시스템 트리거 (시간 경과 cron 등). 클라이언트 호출은 항상 user_id.
    """
    profile = await session.scalar(select(Profile).where(Profile.id == idol_id))
    if profile is None:
        raise NotFoundError("아이돌을 찾을 수 없습니다.")

    state = await session.scalar(select(CharacterState).where(CharacterState.idol_id == idol_id))
    if state is None:
        state = CharacterState(
            idol_id=idol_id,
            current_action=action,
            hunger=_DEFAULT_HUNGER,
            happiness=_DEFAULT_HAPPINESS,
            energy=_DEFAULT_ENERGY,
        )
        session.add(state)
    else:
        state.current_action = action

    log = CharacterActionLog(
        idol_id=idol_id,
        action=action,
        performed_by=performed_by,
    )
    session.add(log)

    await session.flush()
    await session.refresh(log)
    await session.refresh(state)

    return ActionResponse(
        log=ActionLogSummary(
            id=log.id,
            idol_id=log.idol_id,
            action=log.action,
            performed_by=log.performed_by,
            performed_at=log.performed_at,
        ),
        state=_to_state_response(state),
    )


async def save_position(
    session: AsyncSession,
    idol_id: UUID,
    x: float,
    y: float,
) -> CharacterStateResponse:
    """드래그 위치 저장 (PR-G2). state row 없으면 default 값으로 새로 INSERT.

    AuthedUser면 모두 호출 가능 (MVP, record_action과 동일 권한 정책).
    """
    profile = await session.scalar(select(Profile).where(Profile.id == idol_id))
    if profile is None:
        raise NotFoundError("아이돌을 찾을 수 없습니다.")

    state = await session.scalar(select(CharacterState).where(CharacterState.idol_id == idol_id))
    if state is None:
        state = CharacterState(
            idol_id=idol_id,
            hunger=_DEFAULT_HUNGER,
            happiness=_DEFAULT_HAPPINESS,
            energy=_DEFAULT_ENERGY,
            position_x=x,
            position_y=y,
        )
        session.add(state)
    else:
        state.position_x = x
        state.position_y = y

    await session.flush()
    await session.refresh(state)
    return _to_state_response(state)


async def save_furniture(
    session: AsyncSession,
    idol_id: UUID,
    layout: dict,
) -> CharacterStateResponse:
    """가구 배치 저장 (아이돌별, 모든 팬 공유). 본인 권한 체크는 router.

    state row 없으면 default 값 + 배치로 INSERT.
    """
    profile = await session.scalar(select(Profile).where(Profile.id == idol_id))
    if profile is None:
        raise NotFoundError("아이돌을 찾을 수 없습니다.")

    state = await session.scalar(select(CharacterState).where(CharacterState.idol_id == idol_id))
    if state is None:
        state = CharacterState(
            idol_id=idol_id,
            hunger=_DEFAULT_HUNGER,
            happiness=_DEFAULT_HAPPINESS,
            energy=_DEFAULT_ENERGY,
            furniture_layout=layout,
        )
        session.add(state)
    else:
        state.furniture_layout = layout

    await session.flush()
    await session.refresh(state)
    return _to_state_response(state)


def _to_state_response(state: CharacterState) -> CharacterStateResponse:
    return CharacterStateResponse(
        idol_id=state.idol_id,
        current_action=state.current_action,
        hunger=state.hunger,
        happiness=state.happiness,
        energy=state.energy,
        position_x=state.position_x,
        position_y=state.position_y,
        furniture_layout=state.furniture_layout,
        updated_at=state.updated_at,
    )
