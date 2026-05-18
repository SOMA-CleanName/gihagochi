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
import json
from typing import Any

import firebase_admin
from firebase_admin import credentials, messaging

from app.core.config import Settings, get_settings
from app.core.logging import get_logger

_logger = get_logger(__name__)
_initialized = False


def _load_credentials_dict(settings: Settings) -> dict[str, Any] | None:
    """FCM 자격증명 dict 로드. JSON 환경변수 우선, 파일 경로 폴백.

    Cloud 배포(Railway/Vercel 등)는 JSON 통째 주입이 운영상 편함.
    로컬 개발은 파일 경로가 간단.
    """
    if settings.fcm_service_account_json:
        try:
            return json.loads(settings.fcm_service_account_json)
        except json.JSONDecodeError as e:
            _logger.error("fcm_json_parse_failed", reason=str(e))
            return None

    if settings.fcm_service_account_path:
        path = settings.fcm_service_account_path
        if not path.exists():
            _logger.error("fcm_file_missing", path=str(path))
            return None
        try:
            return json.loads(path.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError) as e:
            _logger.error("fcm_file_read_failed", path=str(path), reason=str(e))
            return None

    return None


def _ensure_init() -> bool:
    """첫 호출 시 firebase-admin 초기화. 자격증명 누락이면 False."""
    global _initialized
    if _initialized:
        return True

    settings = get_settings()
    cred_dict = _load_credentials_dict(settings)
    if cred_dict is None:
        _logger.warning(
            "fcm_skipped",
            reason="FCM_SERVICE_ACCOUNT_JSON / PATH 둘 다 미설정 또는 유효하지 않음",
        )
        return False

    try:
        cred = credentials.Certificate(cred_dict)
        firebase_admin.initialize_app(cred)
    except Exception as e:
        _logger.error("fcm_init_failed", reason=str(e))
        return False

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
