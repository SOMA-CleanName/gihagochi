"""스모크 — /health 200 OK.

DB / 인증 의존 X. 앱이 부트만 하면 통과.
"""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_health_ok(client: AsyncClient) -> None:
    response = await client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
