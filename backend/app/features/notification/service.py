"""F-029 / F-031 notification — 서비스 레이어.

device_tokens / notification_prefs owner.

공개 인터페이스 (다른 피처가 호출 가능):
- `get_active_tokens_for_user(session, user_id)` — 푸시 발송 시 토큰 목록
- `is_notification_enabled(session, user_id, kind)` — 발송 전 prefs 체크
"""

from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.features.notification.schemas import (
    DeviceTokenResponse,
    NotificationKind,
    NotificationPrefsPatchRequest,
    NotificationPrefsResponse,
)
from app.shared.enums import DevicePlatform
from app.shared.models import DeviceToken, NotificationPref


# ============================================================
# device_tokens
# ============================================================


async def register_device_token(
    session: AsyncSession,
    user_id: UUID,
    token: str,
    platform: DevicePlatform,
) -> DeviceTokenResponse:
    """FCM 토큰 등록.

    멱등:
    - 같은 token + 같은 user_id → last_used_at만 갱신
    - 같은 token + 다른 user_id → user_id reassign (계정 전환 시 잘못 발송 방지)
    - 토큰 없으면 신규 INSERT
    """
    existing = await session.scalar(
        select(DeviceToken).where(DeviceToken.token == token)
    )
    now = datetime.now(UTC)

    if existing is None:
        row = DeviceToken(user_id=user_id, platform=platform, token=token)
        session.add(row)
        await session.flush()
        await session.refresh(row)
        return _to_token_response(row)

    # 토큰 존재 — user_id/platform reassign + last_used_at 갱신.
    existing.user_id = user_id
    existing.platform = platform
    existing.last_used_at = now
    await session.flush()
    await session.refresh(existing)
    return _to_token_response(existing)


async def unregister_device_token(
    session: AsyncSession,
    user_id: UUID,
    token: str,
) -> None:
    """본인 user_id + 토큰 일치하는 row 삭제. 일치 없으면 멱등 (no-op).

    다른 user의 토큰을 임의로 지우지 못하게 user_id 조건 강제.
    """
    row = await session.scalar(
        select(DeviceToken).where(
            DeviceToken.token == token,
            DeviceToken.user_id == user_id,
        )
    )
    if row is None:
        return
    await session.delete(row)
    await session.flush()


async def get_active_tokens_for_user(
    session: AsyncSession,
    user_id: UUID,
) -> list[DeviceToken]:
    """공개 — 푸시 발송 시 대상 사용자의 모든 FCM 토큰 조회."""
    result = await session.scalars(
        select(DeviceToken).where(DeviceToken.user_id == user_id)
    )
    return list(result.all())


# ============================================================
# notification_prefs
# ============================================================


async def get_or_create_prefs(
    session: AsyncSession,
    user_id: UUID,
) -> NotificationPrefsResponse:
    """GET /notification/prefs — row 없으면 default 생성 후 반환."""
    row = await _load_or_create_prefs(session, user_id)
    return _to_prefs_response(row)


async def update_prefs(
    session: AsyncSession,
    user_id: UUID,
    patch: NotificationPrefsPatchRequest,
) -> NotificationPrefsResponse:
    """PATCH /notification/prefs — 부분 업데이트. row 없으면 default 생성 후 patch."""
    row = await _load_or_create_prefs(session, user_id)
    if patch.new_message_enabled is not None:
        row.new_message_enabled = patch.new_message_enabled
    if patch.idol_reply_enabled is not None:
        row.idol_reply_enabled = patch.idol_reply_enabled
    if patch.marketing_enabled is not None:
        row.marketing_enabled = patch.marketing_enabled
    row.updated_at = datetime.now(UTC)
    await session.flush()
    await session.refresh(row)
    return _to_prefs_response(row)


async def is_notification_enabled(
    session: AsyncSession,
    user_id: UUID,
    kind: NotificationKind,
) -> bool:
    """공개 — 발송 측이 호출. row 없으면 SCHEMA default 기준 반환."""
    row = await session.scalar(
        select(NotificationPref).where(NotificationPref.user_id == user_id)
    )
    if row is None:
        # SCHEMA 4.9 default.
        defaults = {
            "new_message": True,
            "idol_reply": True,
            "marketing": False,
        }
        return defaults[kind]
    field_map = {
        "new_message": row.new_message_enabled,
        "idol_reply": row.idol_reply_enabled,
        "marketing": row.marketing_enabled,
    }
    return field_map[kind]


# ============================================================
# 내부 helper
# ============================================================


async def _load_or_create_prefs(
    session: AsyncSession, user_id: UUID
) -> NotificationPref:
    row = await session.scalar(
        select(NotificationPref).where(NotificationPref.user_id == user_id)
    )
    if row is not None:
        return row
    row = NotificationPref(user_id=user_id)
    session.add(row)
    await session.flush()
    await session.refresh(row)
    return row


def _to_token_response(row: DeviceToken) -> DeviceTokenResponse:
    return DeviceTokenResponse(
        id=row.id,
        user_id=row.user_id,
        platform=row.platform,
        token=row.token,
        created_at=row.created_at,
        last_used_at=row.last_used_at,
    )


def _to_prefs_response(row: NotificationPref) -> NotificationPrefsResponse:
    return NotificationPrefsResponse(
        new_message_enabled=row.new_message_enabled,
        idol_reply_enabled=row.idol_reply_enabled,
        marketing_enabled=row.marketing_enabled,
        updated_at=row.updated_at,
    )
