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


# 비인증 OK라 인증 가드를 통과해 service까지 도달 → profile 조회(DB) 발생.
# 따라서 DB 없는 non-integration job에선 돌면 안 됨 → integration 마커.
@pytest.mark.integration
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


@pytest.mark.asyncio
async def test_post_position_requires_auth(client: AsyncClient) -> None:
    """POST /character/{idol_id}/position은 AuthedUser 필요 (PR-G2)."""
    response = await client.post(
        f"/character/{uuid4()}/position",
        json={"x": 0.0, "y": 80.0},
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_post_furniture_requires_auth(client: AsyncClient) -> None:
    """POST /character/{idol_id}/furniture는 AuthedUser 필요."""
    response = await client.post(
        f"/character/{uuid4()}/furniture",
        json={"layout": {}},
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


@pytest.mark.integration
@pytest.mark.asyncio
async def test_save_position_creates_and_updates(session: AsyncSession, make_fresh_user) -> None:
    """첫 위치 저장 → state row 생성(default + 위치), 재저장 → 위치만 갱신 (PR-G2)."""
    idol_id = make_fresh_user()
    await auth_service.create_signup(session, idol_id, _signup_input("아이돌"))
    await session.flush()

    first = await service.save_position(session, idol_id, 10.0, 20.0)
    assert first.position_x == 10.0
    assert first.position_y == 20.0
    assert first.current_action == CharacterActionType.IDLE

    second = await service.save_position(session, idol_id, -30.0, 80.0)
    assert second.position_x == -30.0
    assert second.position_y == 80.0

    rows = (
        await session.scalars(select(CharacterState).where(CharacterState.idol_id == idol_id))
    ).all()
    assert len(rows) == 1


@pytest.mark.integration
@pytest.mark.asyncio
async def test_get_state_includes_position(session: AsyncSession, make_fresh_user) -> None:
    """저장된 위치가 get_state 응답에 포함 (PR-G2)."""
    idol_id = make_fresh_user()
    await auth_service.create_signup(session, idol_id, _signup_input("아이돌"))
    await session.flush()

    await service.save_position(session, idol_id, 5.0, -15.0)
    result = await service.get_state(session, idol_id)
    assert result.position_x == 5.0
    assert result.position_y == -15.0


@pytest.mark.integration
@pytest.mark.asyncio
async def test_save_furniture_persists_layout(session: AsyncSession, make_fresh_user) -> None:
    """가구 배치 저장 → state row 생성/갱신 + get_state에 포함."""
    idol_id = make_fresh_user()
    await auth_service.create_signup(session, idol_id, _signup_input("아이돌"))
    await session.flush()

    layout = {"bed": {"x": 1.0, "y": 2.0, "w": 3.0}}
    saved = await service.save_furniture(session, idol_id, layout)
    assert saved.furniture_layout is not None
    assert saved.furniture_layout["bed"].w == 3.0

    fetched = await service.get_state(session, idol_id)
    assert fetched.furniture_layout is not None
    assert fetched.furniture_layout["bed"].x == 1.0
