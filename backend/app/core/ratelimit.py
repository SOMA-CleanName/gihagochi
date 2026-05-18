"""slowapi 기반 rate limiter.

사용:
    from fastapi import Request
    from app.core.ratelimit import limiter

    @router.post("/endpoint")
    @limiter.limit("10/minute")
    async def endpoint(request: Request):
        ...

주의:
- 데코레이터 순서: `@router.post` -> `@limiter.limit` (반드시 이 순서).
- 핸들러 함수 시그니처에 `request: Request` 가 있어야 동작.
"""

from fastapi import FastAPI, Request
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from app.core.config import get_settings


def _key_func(request: Request) -> str:
    """인증된 사용자는 user_id, 익명은 IP 기반."""
    user = getattr(request.state, "user", None)
    if user is not None and hasattr(user, "id"):
        return f"user:{user.id}"
    return get_remote_address(request)


limiter = Limiter(
    key_func=_key_func,
    default_limits=[get_settings().rate_limit_default],
)


def register_rate_limiter(app: FastAPI) -> None:
    """main.py 부트스트랩 시 호출. exception handler + state 등록."""
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
