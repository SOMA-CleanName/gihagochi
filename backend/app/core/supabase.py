"""Supabase 클라이언트 (async) 싱글톤.

용도 분리:
- `get_supabase()`     : anon key. RLS 적용. 사용자 컨텍스트 작업.
- `get_supabase_admin()`: service role key. RLS 우회. ★관리/시스템 작업만.

DB 쿼리는 SQLAlchemy(core/db.py) 사용 권장.
Supabase 클라이언트는 Auth admin API / Storage / Realtime broadcast용.
"""

from supabase import AsyncClient, create_async_client

from app.core.config import get_settings

_anon_client: AsyncClient | None = None
_admin_client: AsyncClient | None = None


async def get_supabase() -> AsyncClient:
    """anon 클라이언트. RLS 적용. 일반 사용."""
    global _anon_client
    if _anon_client is None:
        s = get_settings()
        _anon_client = await create_async_client(s.supabase_url, s.supabase_anon_key)
    return _anon_client


async def get_supabase_admin() -> AsyncClient:
    """admin 클라이언트. ★RLS 우회.

    절대 룰:
    - 결과를 사용자 응답에 그대로 노출 금지.
    - 사용자가 제공한 ID를 그대로 쿼리에 넣지 말 것 (권한 검증 선행 필수).
    """
    global _admin_client
    if _admin_client is None:
        s = get_settings()
        _admin_client = await create_async_client(s.supabase_url, s.supabase_service_role_key)
    return _admin_client
