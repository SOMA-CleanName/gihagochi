"""auth 테스트 전용 fixture.

상위 conftest(backend/conftest.py)의 `session`, `client`, `make_auth_headers`는 그대로 사용.
여기는 auth 통합 테스트가 필요한 진짜 `auth.users` row 발급용 헬퍼만 추가.

profiles.id는 auth.users(id) FK라 임의 UUID로 INSERT 불가 →
Supabase Admin API로 진짜 user를 만든 뒤 그 id를 사용해야 함.
"""

from collections.abc import Callable, Iterator
from uuid import UUID, uuid4

import pytest
from supabase import create_client

from app.core.config import get_settings


@pytest.fixture
def make_fresh_user() -> Iterator[Callable[[], UUID]]:
    """진짜 auth.users row를 만들어 그 id(UUID)를 반환하는 factory.

    한 테스트 안에서 여러 user가 필요하면 여러 번 호출. teardown에서 일괄 삭제.

    주의: dev Supabase에 진짜 INSERT/DELETE. SUPABASE_SERVICE_ROLE_KEY 필요.
    """
    settings = get_settings()
    admin = create_client(settings.supabase_url, settings.supabase_service_role_key)

    created: list[UUID] = []

    def _make() -> UUID:
        email = f"test-{uuid4()}@gihagochi-test.local"
        resp = admin.auth.admin.create_user(
            {
                "email": email,
                "password": "TestPass1234!",
                "email_confirm": True,
            }
        )
        # supabase-py 응답 형태: UserResponse with .user.id
        assert resp.user is not None, "auth.admin.create_user가 user를 반환하지 않음"
        user_id = UUID(resp.user.id)
        created.append(user_id)
        return user_id

    yield _make

    # 테스트 끝나면 만든 user 모두 삭제.
    # profiles 행은 ON DELETE CASCADE라 함께 정리됨.
    for uid in created:
        try:
            admin.auth.admin.delete_user(str(uid))
        except Exception:
            # cleanup 실패는 무시 (dev DB 잔존 row는 다음 실행에 영향 X — 매번 새 UUID)
            pass
