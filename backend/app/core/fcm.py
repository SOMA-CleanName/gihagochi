"""FCM 푸시 발송.

토큰 리스트가 input. `user_id -> token list` 조회는 `features/notification/`에서.
이 모듈은 schema-independent (DB 의존 없음).

사용:
    from app.core.fcm import send_push_to_tokens

    tokens = await fetch_tokens_for_user(user_id)  # notification 피처에서
    await send_push_to_tokens(
        tokens=tokens,
        title="새 메시지",
        body=preview,
        data={"room_id": str(idol_id)},  # 모든 값은 str (FCM 제약)
    )
"""

import asyncio
from typing import Any

import firebase_admin
from firebase_admin import credentials, messaging

from app.core.config import get_settings
from app.core.logging import get_logger

_logger = get_logger(__name__)
_initialized = False


def _ensure_init() -> bool:
    """첫 호출 시 firebase-admin 초기화. 설정 누락이면 False."""
    global _initialized
    if _initialized:
        return True

    settings = get_settings()
    if not settings.fcm_service_account_path:
        _logger.warning("fcm_skipped", reason="FCM_SERVICE_ACCOUNT_PATH 미설정")
        return False

    if not settings.fcm_service_account_path.exists():
        _logger.error(
            "fcm_init_failed",
            reason="service account 파일 없음",
            path=str(settings.fcm_service_account_path),
        )
        return False

    cred = credentials.Certificate(str(settings.fcm_service_account_path))
    firebase_admin.initialize_app(cred)
    _initialized = True
    return True


async def send_push_to_tokens(
    tokens: list[str],
    title: str,
    body: str,
    data: dict[str, str] | None = None,
) -> Any | None:
    """주어진 토큰 리스트에 multicast 푸시.

    Returns:
        BatchResponse | None — 설정 누락 또는 빈 토큰 리스트면 None.
    """
    if not tokens:
        return None
    if not _ensure_init():
        return None

    message = messaging.MulticastMessage(
        notification=messaging.Notification(title=title, body=body),
        data=data or {},
        tokens=tokens,
    )

    # firebase-admin은 sync. async 컨텍스트에서 안전하게 호출.
    response = await asyncio.to_thread(messaging.send_each_for_multicast, message)

    _logger.info(
        "fcm_push_sent",
        token_count=len(tokens),
        success=response.success_count,
        failure=response.failure_count,
    )
    return response
