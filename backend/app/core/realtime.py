"""Supabase Realtime — 서버측 broadcast 보조.

대부분의 메시지 broadcast는 DB trigger (`realtime.broadcast_changes`)가 처리.
이 모듈은 trigger 외 시나리오 (관리자 액션, 시스템 알림 등)에서 직접 broadcast.

토픽 컨벤션:
- 아이돌 채팅방: `idol:<idol_id>`  (PROJECT.md §3.1, SCHEMA의 트리거와 일치)

사용:
    await broadcast_to_idol_topic(idol_id, "system_notice", {"text": "..."})
"""

from typing import Any
from uuid import UUID

from app.core.logging import get_logger
from app.core.supabase import get_supabase_admin

_logger = get_logger(__name__)


def idol_topic(idol_id: UUID | str) -> str:
    """아이돌 채팅방 Realtime 토픽 이름."""
    return f"idol:{idol_id}"


async def broadcast_to_idol_topic(
    idol_id: UUID | str,
    event: str,
    payload: dict[str, Any],
) -> None:
    """idol 채팅방 구독자 전원에게 broadcast.

    내부적으로 supabase-py async client의 realtime broadcast 사용.
    채널 권한은 Supabase realtime RLS 정책에서 검증.
    """
    client = await get_supabase_admin()
    topic = idol_topic(idol_id)

    # TODO: supabase-py 2.x realtime broadcast API는 아직 안정화 진행 중.
    # 동작 불안정 시 fallback: POST {SUPABASE_URL}/realtime/v1/api/broadcast 직접 호출.
    channel = client.channel(topic)
    await channel.send_broadcast(event, payload)

    _logger.info("realtime_broadcast", topic=topic, event=event)
