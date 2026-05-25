"""F-012 / F-013 subscription — 서비스 레이어.

subscriptions 테이블 owner. 재구독은 같은 row의 UPDATE (SCHEMA.md §6.3).

공개 인터페이스:
- `is_subscribed(session, fan_id, idol_id)` — active 응원 여부
- `get_subscription(session, fan_id, idol_id)` — 단건 조회 (활성/비활성 무관)
"""

from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError, ValidationError
from app.features.subscription.schemas import SubscriptionDetail
from app.shared.enums import UserRole, UserStatus
from app.shared.models import IdolProfile, Profile, Subscription


def _active_idol_filter() -> list:
    """idol_discovery와 동일한 활성 정의."""
    return [
        Profile.role == UserRole.IDOL,
        Profile.status == UserStatus.ACTIVE,
        Profile.deleted_at.is_(None),
    ]


# ============================================================
# F-012 응원 시작
# ============================================================


async def subscribe(
    session: AsyncSession,
    fan_id: UUID,
    idol_id: UUID,
) -> SubscriptionDetail:
    """응원 시작 — 신규 INSERT 또는 재구독(같은 row UPDATE).

    실패:
    - 400 ValidationError: 자기 자신 응원
    - 404 NotFoundError: 비활성 아이돌
    """
    if fan_id == idol_id:
        raise ValidationError("본인을 응원할 수 없습니다.")

    # 활성 아이돌 검증.
    idol_stmt = (
        select(IdolProfile)
        .join(Profile, Profile.id == IdolProfile.id)
        .where(and_(IdolProfile.id == idol_id, *_active_idol_filter()))
    )
    idol = await session.scalar(idol_stmt)
    if idol is None:
        raise NotFoundError("아이돌을 찾을 수 없습니다.")

    # 기존 row 조회.
    existing = await session.scalar(
        select(Subscription).where(
            Subscription.fan_id == fan_id,
            Subscription.idol_id == idol_id,
        )
    )

    now = datetime.now(UTC)

    if existing is None:
        # 신규 INSERT.
        sub = Subscription(
            fan_id=fan_id,
            idol_id=idol_id,
        )
        session.add(sub)
        await session.flush()
        await session.refresh(sub)
        return _to_detail(sub)

    if existing.unsubscribed_at is None:
        # 이미 active — 멱등.
        return _to_detail(existing)

    # 재구독 — 같은 row 복원.
    existing.unsubscribed_at = None
    existing.last_read_at = now
    await session.flush()
    await session.refresh(existing)
    return _to_detail(existing)


# ============================================================
# F-013 응원 취소
# ============================================================


async def unsubscribe(
    session: AsyncSession,
    fan_id: UUID,
    idol_id: UUID,
) -> SubscriptionDetail:
    """응원 취소 — unsubscribed_at=NOW() UPDATE.

    실패:
    - 404 NotFoundError: row 자체가 없음 (한 번도 응원 안 함)
    """
    sub = await session.scalar(
        select(Subscription).where(
            Subscription.fan_id == fan_id,
            Subscription.idol_id == idol_id,
        )
    )
    if sub is None:
        raise NotFoundError("응원 기록을 찾을 수 없습니다.")

    if sub.unsubscribed_at is not None:
        # 이미 unsubscribed — 멱등.
        return _to_detail(sub)

    sub.unsubscribed_at = datetime.now(UTC)
    await session.flush()
    await session.refresh(sub)
    return _to_detail(sub)


# ============================================================
# 공개 인터페이스
# ============================================================


async def is_subscribed(session: AsyncSession, fan_id: UUID, idol_id: UUID) -> bool:
    """active 응원 여부. 다른 슬라이스가 표시용으로 호출."""
    sub = await session.scalar(
        select(Subscription).where(
            Subscription.fan_id == fan_id,
            Subscription.idol_id == idol_id,
            Subscription.unsubscribed_at.is_(None),
        )
    )
    return sub is not None


async def get_subscription(
    session: AsyncSession, fan_id: UUID, idol_id: UUID
) -> SubscriptionDetail | None:
    """단건 조회 — 활성/비활성 무관. row 없으면 None."""
    sub = await session.scalar(
        select(Subscription).where(
            Subscription.fan_id == fan_id,
            Subscription.idol_id == idol_id,
        )
    )
    return _to_detail(sub) if sub else None


# ============================================================
# 내부 매퍼
# ============================================================


def _to_detail(sub: Subscription) -> SubscriptionDetail:
    return SubscriptionDetail(
        fan_id=sub.fan_id,
        idol_id=sub.idol_id,
        subscribed_at=sub.subscribed_at,
        unsubscribed_at=sub.unsubscribed_at,
        last_read_at=sub.last_read_at,
        is_active=sub.unsubscribed_at is None,
    )
