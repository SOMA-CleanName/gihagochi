"""F-029 / F-031 notification — 라우터/서비스 테스트.

- 라우터: 인증 가드 (401)
- 스키마: Pydantic validator (빈 PATCH 차단, 빈 토큰 차단)
- 서비스: 분기 (default-on-no-row, unregister 멱등) — integration, dev DB 필요
"""

from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

# ============================================================
# 라우터 — 인증 가드 (401)
# ============================================================


@pytest.mark.asyncio
async def test_register_device_token_requires_auth(client: AsyncClient) -> None:
    response = await client.post(
        "/notification/device-tokens",
        json={"token": "fcm-test", "platform": "ios"},
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_unregister_device_token_requires_auth(client: AsyncClient) -> None:
    response = await client.delete("/notification/device-tokens?token=fcm-test")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_get_prefs_requires_auth(client: AsyncClient) -> None:
    response = await client.get("/notification/prefs")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_patch_prefs_requires_auth(client: AsyncClient) -> None:
    response = await client.patch(
        "/notification/prefs",
        json={"marketing_enabled": True},
    )
    assert response.status_code == 401


# ============================================================
# 스키마 — Pydantic validator
# ============================================================


def test_patch_prefs_empty_body_rejected() -> None:
    """모든 필드 None → ValidationError."""
    from pydantic import ValidationError as PydValidationError

    from app.features.notification.schemas import NotificationPrefsPatchRequest

    with pytest.raises(PydValidationError):
        NotificationPrefsPatchRequest()


def test_patch_prefs_single_field_ok() -> None:
    """1개 필드만 있어도 통과."""
    from app.features.notification.schemas import NotificationPrefsPatchRequest

    patch = NotificationPrefsPatchRequest(marketing_enabled=True)
    assert patch.marketing_enabled is True
    assert patch.new_message_enabled is None


def test_register_token_empty_string_rejected() -> None:
    """빈 토큰 → ValidationError."""
    from pydantic import ValidationError as PydValidationError

    from app.features.notification.schemas import DeviceTokenRegisterRequest

    with pytest.raises(PydValidationError):
        DeviceTokenRegisterRequest(token="", platform="ios")  # type: ignore[arg-type]


# ============================================================
# 서비스 — DB 의존 통합
# ============================================================


@pytest.mark.integration
@pytest.mark.asyncio
async def test_is_notification_enabled_defaults_when_no_row(
    session: AsyncSession,
) -> None:
    """prefs row 없으면 SCHEMA default 반환."""
    from app.features.notification import service

    fake_user = uuid4()
    assert await service.is_notification_enabled(session, fake_user, "new_message") is True
    assert await service.is_notification_enabled(session, fake_user, "idol_reply") is True
    assert await service.is_notification_enabled(session, fake_user, "marketing") is False


@pytest.mark.integration
@pytest.mark.asyncio
async def test_get_active_tokens_empty(session: AsyncSession) -> None:
    """토큰 없는 사용자 → 빈 리스트."""
    from app.features.notification import service

    tokens = await service.get_active_tokens_for_user(session, uuid4())
    assert tokens == []
