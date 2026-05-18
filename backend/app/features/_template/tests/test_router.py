"""F-XXX 기능명 — 라우터 테스트 (패턴 예시).

`_template`은 auto-register에서 스킵되므로 라우터 호출 테스트는 `skip`.
복사 후 폴더명 변경하면 자동으로 동작.

권장 패턴:
- 인증 가드 테스트 1개 (401 응답 확인)
- 정상 케이스 1개 (200 응답 + body)
- 비즈니스 룰 분기마다 1개 (예: 권한 부족 시 403, 리소스 없을 때 404)
"""

from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError
from app.features._template.service import get_example


@pytest.mark.skip(reason="_template은 라우터 미등록. 복사 후 활성화.")
@pytest.mark.asyncio
async def test_example_requires_auth(client: AsyncClient) -> None:
    """인증 없이 호출 → 401."""
    response = await client.get("/template/me")
    assert response.status_code == 401


@pytest.mark.skip(reason="_template은 라우터 미등록. 복사 후 활성화.")
@pytest.mark.asyncio
async def test_example_returns_profile(
    client: AsyncClient,
    make_auth_headers,
) -> None:
    """정상 호출 → 200 + 본인 프로필."""
    user_id = uuid4()
    # 사전 조건: profiles에 user_id 행 INSERT (fixture 또는 setup으로)
    headers = make_auth_headers(user_id=user_id)
    response = await client.get("/template/me", headers=headers)
    assert response.status_code == 200
    body = response.json()
    assert body["user_id"] == str(user_id)


@pytest.mark.asyncio
async def test_service_raises_when_profile_missing(session: AsyncSession) -> None:
    """서비스 레이어 단위 테스트 — 프로필 없으면 NotFoundError."""
    with pytest.raises(NotFoundError):
        await get_example(session, uuid4())
