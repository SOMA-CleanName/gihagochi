"""FastAPI 앱 부트스트랩 + 피처 라우터 자동 등록.

새 피처 추가 시 main.py 수정 X. `app/features/<폴더>/router.py`에 `router = APIRouter(...)`
export만 하면 자동 마운트. `_` 시작 폴더는 스킵 (`_template`).

부트 순서 (lifespan):
1. setup_logging() — structlog 셋업
2. Sentry init (DSN 있으면)
3. 핸들러 / 미들웨어 / 라우터 등록 (앱 생성 시점)
"""

import importlib
import pkgutil
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import sentry_sdk
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app import features as features_pkg
from app.core.config import Settings, get_settings
from app.core.errors import register_error_handlers
from app.core.logging import get_logger, setup_logging
from app.core.ratelimit import register_rate_limiter

_logger = get_logger(__name__)


def _init_sentry(settings: Settings) -> None:
    if not settings.sentry_dsn:
        return
    # sentry-sdk[fastapi]는 FastAPI/Starlette integration 자동 감지.
    sentry_sdk.init(
        dsn=settings.sentry_dsn,
        environment=settings.env,
        traces_sample_rate=1.0 if settings.is_dev else 0.1,
        send_default_pii=False,
    )


def _auto_register_routers(app: FastAPI) -> None:
    """app/features/<폴더>/router.py를 자동 import + 등록.

    규칙:
    - 폴더명 `_` 시작 → 스킵 (`_template` 등)
    - `router.py` 없음 → 경고 후 스킵
    - `router` symbol 미export → 경고 후 스킵
    """
    for info in pkgutil.iter_modules(features_pkg.__path__):
        if info.name.startswith("_"):
            continue
        module_path = f"app.features.{info.name}.router"
        try:
            module = importlib.import_module(module_path)
        except ModuleNotFoundError:
            _logger.warning("feature_router_missing", feature=info.name, path=module_path)
            continue
        router = getattr(module, "router", None)
        if router is None:
            _logger.warning("feature_router_export_missing", feature=info.name)
            continue
        app.include_router(router)
        _logger.info("feature_router_registered", feature=info.name)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    settings = get_settings()
    setup_logging()
    _init_sentry(settings)
    _logger.info("app_starting", env=settings.env, app_name=settings.app_name)
    yield
    _logger.info("app_shutting_down")


def create_app() -> FastAPI:
    settings = get_settings()

    app = FastAPI(
        title=settings.app_name,
        version="0.1.0",
        lifespan=lifespan,
    )

    # CORS — dev는 전체 허용. prod는 명시적 origin만.
    # TODO: prod origin 확정 시 settings에 추가하고 분기.
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"] if settings.is_dev else [],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    register_error_handlers(app)
    register_rate_limiter(app)
    _auto_register_routers(app)

    @app.get("/health", tags=["meta"])
    async def health() -> dict[str, str]:
        """헬스체크. Railway/Render의 healthcheck endpoint."""
        return {"status": "ok"}

    return app


app = create_app()
