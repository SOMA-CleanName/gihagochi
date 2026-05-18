"""Alembic 환경 설정 (sync, psycopg v3).

- DATABASE_URL 환경변수로 접속 정보 주입 (backend/.env 도 자동 로드)
- raw SQL 마이그레이션이므로 SQLAlchemy metadata 없음 (target_metadata = None)
- 마이그레이션은 sync psycopg 사용. Phase 2 runtime은 asyncpg 별도.
  (asyncpg 는 prepared statement당 1 command 만 허용 -> 초기 multi-statement 블록과 충돌)
"""

from __future__ import annotations

import os
from logging.config import fileConfig
from pathlib import Path

from alembic import context
from sqlalchemy import engine_from_config, pool

# .env 파일 자동 로드 (backend/.env). gitignored 이므로 비밀번호 포함 가능.
# 우선순위: shell 환경변수 > .env 파일 (override=False)
try:
    from dotenv import load_dotenv

    _env_path = Path(__file__).resolve().parents[1] / ".env"
    if _env_path.exists():
        load_dotenv(_env_path, override=False)
except ImportError:
    # python-dotenv 미설치 시 shell 환경변수만 사용
    pass

# Alembic Config 객체. .ini 파일의 값에 접근 가능.
config = context.config

# 로깅 설정
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# 환경변수에서 DB URL 주입
# 형식: postgresql://USER:PASSWORD@HOST:PORT/DB  (Supabase Session Pooler 권장)
db_url = os.environ.get("DATABASE_URL")
if not db_url:
    raise RuntimeError(
        "DATABASE_URL 환경변수가 필요합니다. backend/.env 또는 shell에 세팅."
    )

# psycopg v3 드라이버로 강제 (sync). asyncpg URL 이면 변환.
if db_url.startswith("postgresql+asyncpg://"):
    db_url = db_url.replace("postgresql+asyncpg://", "postgresql+psycopg://", 1)
elif db_url.startswith("postgresql://"):
    db_url = db_url.replace("postgresql://", "postgresql+psycopg://", 1)

config.set_main_option("sqlalchemy.url", db_url)

# 현재 마이그레이션은 raw SQL 기반. metadata autogenerate 미사용.
target_metadata = None


def run_migrations_offline() -> None:
    """offline 모드 (SQL 파일만 생성). CI 등에서 사용 가능."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """online 모드 (실제 DB 연결, sync)."""
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            transaction_per_migration=True,
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
