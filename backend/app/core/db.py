"""SQLAlchemy 2 async 엔진 / 세션 / Base.

- 엔진: asyncpg + Supabase Session Pooler.
- Base: 모든 ORM 모델의 기반 (`shared/models/`에서 import).
- get_session: FastAPI Depends 주입용. 요청당 1개 세션, 자동 commit/rollback.
"""

from collections.abc import AsyncIterator

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase

from app.core.config import get_settings


class Base(DeclarativeBase):
    """모든 ORM 모델의 기반 클래스. shared/models/에서 상속."""


_settings = get_settings()

engine = create_async_engine(
    _settings.database_url_async,
    echo=_settings.is_dev,
    pool_pre_ping=True,    # stale connection 자동 감지
    pool_size=10,
    max_overflow=20,
)

SessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,   # commit 후에도 ORM 객체 접근 가능
    autoflush=False,
)


async def get_session() -> AsyncIterator[AsyncSession]:
    """FastAPI Depends에 주입. 요청당 1개 세션.

    정상 종료 시 자동 commit, 예외 시 자동 rollback.
    명시적 트랜잭션이 필요한 service는 `async with session.begin()` 사용.
    """
    async with SessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
