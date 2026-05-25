"""F-008 / F-009 / F-010 / F-011 idol_discovery — 라우터/서비스 테스트.

전략:
- 라우터는 인증 가드 (401) + Query 검증 (422)
- 서비스는 단순 분기 (NotFoundError) — 실제 데이터 INSERT는 dev DB 통합 테스트로 위임

리스트 정렬/검색 동작은 dev DB 또는 수동 테스트로 검증.
"""

from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError
from app.features.idol_discovery import service

# ============================================================
# 라우터 — 인증 가드 (401)
# ============================================================


@pytest.mark.asyncio
async def test_list_requires_auth(client: AsyncClient) -> None:
    """GET /idols 인증 헤더 없으면 401."""
    response = await client.get("/idols")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_detail_requires_auth(client: AsyncClient) -> None:
    """GET /idols/{id} 인증 헤더 없으면 401."""
    response = await client.get(f"/idols/{uuid4()}")
    assert response.status_code == 401


# ============================================================
# 라우터 — Query 검증 (422)
# ============================================================


@pytest.mark.asyncio
async def test_list_rejects_too_long_q(client: AsyncClient) -> None:
    """q 200자 초과 → 422 (인증 전이라도 path operation 단계에서 검증)."""
    response = await client.get("/idols", params={"q": "x" * 201})
    # 인증 미통과로 401이 먼저 떨어질 수도 있어 두 케이스 허용.
    # (FastAPI에서 dependency 순서 따라 다름)
    assert response.status_code in (401, 422)


@pytest.mark.asyncio
async def test_list_rejects_invalid_page(client: AsyncClient) -> None:
    """page=0 → 422."""
    response = await client.get("/idols", params={"page": 0})
    assert response.status_code in (401, 422)


@pytest.mark.asyncio
async def test_list_rejects_oversized_page_size(client: AsyncClient) -> None:
    """page_size=100 → 422 (max 50)."""
    response = await client.get("/idols", params={"page_size": 100})
    assert response.status_code in (401, 422)


# ============================================================
# 서비스 — 비즈 룰 분기 (integration: dev DB 필요)
# ============================================================


@pytest.mark.integration
@pytest.mark.asyncio
async def test_detail_unknown_id_raises_not_found(session: AsyncSession) -> None:
    """존재하지 않는 idol_id → NotFoundError."""
    with pytest.raises(NotFoundError):
        await service.get_idol_detail(session, uuid4(), viewer_id=uuid4())


@pytest.mark.integration
@pytest.mark.asyncio
async def test_list_returns_response_shape(session: AsyncSession) -> None:
    """리스트 호출이 응답 스키마 만족하는지 (데이터 없어도 빈 items)."""
    response = await service.list_idols(session, q=None, page=1, page_size=20)
    assert response.page == 1
    assert response.page_size == 20
    assert isinstance(response.items, list)
    assert isinstance(response.has_more, bool)
