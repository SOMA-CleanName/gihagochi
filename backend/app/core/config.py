"""환경변수 설정 — pydantic-settings 기반.

전 영역에서 `get_settings()` 싱글톤으로 접근.
"""

from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic import Field, computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ── 환경 ──
    env: Literal["dev", "prod"] = "dev"
    app_name: str = "gihagochi-backend"
    log_level: Literal["DEBUG", "INFO", "WARNING", "ERROR"] = "INFO"

    # ── DB ──
    # 사용자는 `postgresql://...` 형태로 저장 (Supabase Studio 복사 그대로).
    # 드라이버별 변환은 computed property로 처리.
    database_url: str = Field(..., description="postgresql://... (드라이버 prefix 없이)")

    # ── Supabase ──
    supabase_url: str = Field(..., description="https://<project>.supabase.co")
    supabase_anon_key: str = Field(..., description="public anon key")
    supabase_service_role_key: str = Field(..., description="관리용. RLS 우회. 응답에 노출 금지.")
    supabase_jwt_secret: str = Field(..., description="JWT 서명 검증용")

    # ── FCM ──
    fcm_service_account_path: Path | None = Field(
        default=None,
        description="firebase-admin 서비스 어카운트 JSON 경로. None이면 푸시 발송 비활성.",
    )

    # ── Sentry ──
    sentry_dsn: str | None = None

    # ── Rate limit ──
    rate_limit_default: str = "60/minute"

    @computed_field  # type: ignore[prop-decorator]
    @property
    def database_url_async(self) -> str:
        """SQLAlchemy async 엔진용. asyncpg 드라이버로 변환."""
        url = self.database_url
        if url.startswith("postgresql+asyncpg://"):
            return url
        if url.startswith("postgresql+psycopg://"):
            return "postgresql+asyncpg://" + url[len("postgresql+psycopg://") :]
        if url.startswith("postgresql://"):
            return "postgresql+asyncpg://" + url[len("postgresql://") :]
        return url

    @computed_field  # type: ignore[prop-decorator]
    @property
    def is_dev(self) -> bool:
        return self.env == "dev"


@lru_cache
def get_settings() -> Settings:
    """Settings 싱글톤. lru_cache로 1회 인스턴스화."""
    return Settings()  # type: ignore[call-arg]
