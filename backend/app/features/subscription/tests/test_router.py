"""F-012 / F-013 subscription — 라우터/서비스 테스트.

- 라우터: 인증 가드 (401)
- 서비스: 분기 (자기 응원 차단, 비활성 아이돌 404, 없는 row 취소 404)

INSERT/UPDATE 동작 통합 테스트는 dev DB + make_fresh_user 필요 → 수동 시나리오로 위임.
"""

from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError, ValidationError
from app.features.subscription import service

# ============================================================
# 라우터 — 인증 가드 (401)
# ============================================================


@pytest.mark.asyncio
async def test_subscribe_requires_auth(client: AsyncClient) -> None:
    response = await client.post(f"/idols/{uuid4()}/subscribe")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_unsubscribe_requires_auth(client: AsyncClient) -> None:
    response = await client.delete(f"/idols/{uuid4()}/subscribe")
    assert response.status_code == 401


# ============================================================
# 서비스 — 비즈 룰 분기 (integration: dev DB 필요)
# ============================================================


@pytest.mark.integration
@pytest.mark.asyncio
async def test_subscribe_self_raises_validation(session: AsyncSession) -> None:
    """자기 응원 시도 → ValidationError."""
    same_id = uuid4()
    with pytest.raises(ValidationError):
        await service.subscribe(session, fan_id=same_id, idol_id=same_id)


@pytest.mark.integration
@pytest.mark.asyncio
async def test_subscribe_inactive_idol_raises_not_found(session: AsyncSession) -> None:
    """비활성/존재하지 않는 아이돌 → NotFoundError."""
    with pytest.raises(NotFoundError):
        await service.subscribe(session, fan_id=uuid4(), idol_id=uuid4())


@pytest.mark.integration
@pytest.mark.asyncio
async def test_unsubscribe_without_row_raises_not_found(session: AsyncSession) -> None:
    """한 번도 응원 안 한 row 취소 → NotFoundError."""
    with pytest.raises(NotFoundError):
        await service.unsubscribe(session, fan_id=uuid4(), idol_id=uuid4())


@pytest.mark.integration
@pytest.mark.asyncio
async def test_is_subscribed_false_when_no_row(session: AsyncSession) -> None:
    """row 없으면 is_subscribed=False."""
    result = await service.is_subscribed(session, fan_id=uuid4(), idol_id=uuid4())
    assert result is False


@pytest.mark.integration
@pytest.mark.asyncio
async def test_get_subscription_none_when_no_row(session: AsyncSession) -> None:
    """row 없으면 None."""
    result = await service.get_subscription(session, fan_id=uuid4(), idol_id=uuid4())
    assert result is None
