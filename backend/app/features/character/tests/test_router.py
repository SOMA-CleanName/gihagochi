"""F-042/F-043 character — 라우터/서비스 테스트.

전략:
- 라우터는 인증 가드 / 공개 endpoint 동작 확인
- 서비스는 conftest의 rollback session으로 비즈니스 룰 검증
"""

from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError
from app.features.auth import service as auth_service
from app.features.auth.schemas import (
    AgreementInput,
    AgreementsInput,
    SignupRequest,
)
from app.features.character import service
from app.shared.enums import CharacterActionType
from app.shared.models import CharacterActionLog, CharacterState


def _signup_input(name: str) -> SignupRequest:
    terms = auth_service.get_current_terms()
    return SignupRequest(
        as_="fan",  # type: ignore[call-arg]
        display_name=name,
        agreements=AgreementsInput(
            tos=AgreementInput(version=terms.tos),
            privacy=AgreementInput(version=terms.privacy),
        ),
    )


# ============================================================
# 라우터 — 가드
# ============================================================


@pytest.mark.asyncio
async def test_get_state_unknown_idol_returns_404(client: AsyncClient) -> None:
    """GET /character/{idol_id}/state — 비인증 OK, 존재하지 않으면 404."""
    response = await client.get(f"/character/{uuid4()}/state")
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_post_action_requires_auth(client: AsyncClient) -> None:
    """POST /character/{idol_id}/actions는 AuthedUser 필요."""
    response = await client.post(
        f"/character/{uuid4()}/actions",
        json={"action": "happy"},
    )
    assert response.status_code == 401


# ============================================================
# 서비스 — 비즈니스 룰
# ============================================================


@pytest.mark.integration
@pytest.mark.asyncio
async def test_get_state_returns_default_when_no_row(
    session: AsyncSession, make_fresh_user
) -> None:
    """state row 없으면 default (idle, 100/100/100) — DB INSERT 없음."""
    idol_id = make_fresh_user()
    await auth_service.create_signup(session, idol_id, _signup_input("아이돌"))
    await session.flush()

    result = await service.get_state(session, idol_id)
    assert result.current_action == CharacterActionType.IDLE
    assert result.hunger == 100
    assert result.happiness == 100
    assert result.energy == 100

    row = await session.scalar(select(CharacterState).where(CharacterState.idol_id == idol_id))
    assert row is None


@pytest.mark.integration
@pytest.mark.asyncio
async def test_get_state_unknown_idol_raises(session: AsyncSession) -> None:
    """존재하지 않는 idol_id → NotFoundError."""
    with pytest.raises(NotFoundError):
        await service.get_state(session, uuid4())


@pytest.mark.integration
@pytest.mark.asyncio
async def test_record_action_creates_state_and_log(session: AsyncSession, make_fresh_user) -> None:
    """첫 action → state row 새로 생성 + log 1건."""
    idol_id = make_fresh_user()
    actor_id = make_fresh_user()
    await auth_service.create_signup(session, idol_id, _signup_input("아이돌"))
    await auth_service.create_signup(session, actor_id, _signup_input("팬"))
    await session.flush()

    result = await service.record_action(session, idol_id, CharacterActionType.HAPPY, actor_id)
    assert result.state.current_action == CharacterActionType.HAPPY
    assert result.log.action == CharacterActionType.HAPPY
    assert result.log.performed_by == actor_id

    state_row = await session.scalar(
        select(CharacterState).where(CharacterState.idol_id == idol_id)
    )
    assert state_row is not None
    assert state_row.current_action == CharacterActionType.HAPPY

    log_rows = (
        await session.scalars(
            select(CharacterActionLog).where(CharacterActionLog.idol_id == idol_id)
        )
    ).all()
    assert len(log_rows) == 1


@pytest.mark.integration
@pytest.mark.asyncio
async def test_record_action_updates_existing_state(session: AsyncSession, make_fresh_user) -> None:
    """기존 state row가 있으면 current_action만 업데이트 + log append."""
    idol_id = make_fresh_user()
    await auth_service.create_signup(session, idol_id, _signup_input("아이돌"))
    await session.flush()

    await service.record_action(session, idol_id, CharacterActionType.EAT, idol_id)
    await service.record_action(session, idol_id, CharacterActionType.SLEEP, idol_id)
    await session.flush()

    state_row = await session.scalar(
        select(CharacterState).where(CharacterState.idol_id == idol_id)
    )
    assert state_row is not None
    assert state_row.current_action == CharacterActionType.SLEEP

    log_rows = (
        await session.scalars(
            select(CharacterActionLog).where(CharacterActionLog.idol_id == idol_id)
        )
    ).all()
    assert len(log_rows) == 2
