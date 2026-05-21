"""테스트 공용 픽스처.

위치: backend/ 루트. pytest가 위로 올라가며 자동 발견.
모든 테스트(tests/, app/features/*/tests/) 에서 사용 가능.

제공:
- `client`: FastAPI 앱에 ASGI 직결한 httpx AsyncClient (실제 네트워크 X)
- `session`: AsyncSession. 테스트 끝나면 rollback (격리)
- `make_auth_headers`: 가짜 JWT 발급 헬퍼

주의:
- `session`은 실제 dev DB에 연결. .env의 DATABASE_URL이 dev여야 안전.
- rollback 격리이므로 commit하면 다른 테스트에 영향.
"""

import asyncio
import sys
from collections.abc import AsyncIterator, Callable
from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

import jwt
import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.db import SessionLocal
from app.main import app

# Windows + Python 3.14 + asyncpg 조합에서 ProactorEventLoop이 connection
# teardown 중 "Event loop is closed" race를 일으켜 테스트 격리가 깨짐.
# SelectorEventLoop은 race가 없음 (asyncpg 공식 권장 조합).
# import 시점에 정책 변경 — 이후 생성되는 모든 event loop에 적용.
if sys.platform == "win32":
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())


@pytest_asyncio.fixture
async def client() -> AsyncIterator[AsyncClient]:
    """FastAPI 앱에 ASGI transport로 직결. 네트워크 안 탐."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest_asyncio.fixture
async def session() -> AsyncIterator[AsyncSession]:
    """AsyncSession. 테스트 종료 시 rollback (테스트 간 격리)."""
    async with SessionLocal() as s:
        try:
            yield s
        finally:
            await s.rollback()


@pytest.fixture
def make_auth_headers() -> Callable[..., dict[str, str]]:
    """가짜 JWT 헤더 생성 헬퍼. SUPABASE_JWT_SECRET로 서명.

    사용:
        headers = make_auth_headers(user_id=some_uuid, role="fan")
        await client.get("/me", headers=headers)
    """

    def _make(
        user_id: UUID | None = None,
        role: str = "fan",
        expires_in_minutes: int = 60,
    ) -> dict[str, str]:
        settings = get_settings()
        payload = {
            "sub": str(user_id or uuid4()),
            "role": role,
            "aud": "authenticated",
            "exp": datetime.now(UTC) + timedelta(minutes=expires_in_minutes),
        }
        token = jwt.encode(payload, settings.supabase_jwt_secret, algorithm="HS256")
        return {"Authorization": f"Bearer {token}"}

    return _make
