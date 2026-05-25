"""F-008 / F-009 / F-010 / F-011 idol_discovery — 서비스 레이어.

활성 아이돌 정의 = idol_profiles 존재 AND profiles.role='idol' AND status='active' AND deleted_at IS NULL.
모든 쿼리의 베이스.

공개 인터페이스 (다른 피처가 호출 가능): 없음. idol_discovery는 leaf.
"""

from uuid import UUID

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError
from app.features.idol_discovery.schemas import (
    IdolDetailResponse,
    IdolListItem,
    IdolListResponse,
)
from app.shared.enums import UserRole, UserStatus
from app.shared.models import IdolProfile, Profile, Subscription

# 카드용 bio 요약 길이. 너무 길면 가독성 떨어짐.
_BIO_SUMMARY_LEN = 100


def _active_idol_filter() -> list:
    """모든 쿼리에 공통으로 들어가는 활성 조건. WHERE 절 리스트로 반환."""
    return [
        Profile.role == UserRole.IDOL,
        Profile.status == UserStatus.ACTIVE,
        Profile.deleted_at.is_(None),
    ]


# ============================================================
# GET /idols — 리스트 + 검색 + 페이지네이션
# ============================================================


async def list_idols(
    session: AsyncSession,
    q: str | None,
    page: int,
    page_size: int,
) -> IdolListResponse:
    """활성 아이돌 리스트. activated_at DESC 고정 정렬."""
    stmt = (
        select(IdolProfile, Profile)
        .join(Profile, Profile.id == IdolProfile.id)
        .where(and_(*_active_idol_filter()))
        .order_by(IdolProfile.activated_at.desc())
    )

    if q:
        # ILIKE 부분 일치. SQLAlchemy가 파라미터 바인딩해줘서 안전.
        stmt = stmt.where(IdolProfile.stage_name.ilike(f"%{q}%"))

    # has_more 계산을 위해 +1 fetch.
    offset = (page - 1) * page_size
    stmt = stmt.offset(offset).limit(page_size + 1)

    rows = (await session.execute(stmt)).all()
    has_more = len(rows) > page_size
    rows = rows[:page_size]

    items = [_to_list_item(idol) for (idol, _profile) in rows]
    return IdolListResponse(
        items=items,
        page=page,
        page_size=page_size,
        has_more=has_more,
    )


# ============================================================
# GET /idols/{idol_id} — 상세
# ============================================================


async def get_idol_detail(
    session: AsyncSession,
    idol_id: UUID,
    viewer_id: UUID,
) -> IdolDetailResponse:
    """아이돌 상세 + 응원 팬 수 + 본인 응원 여부.

    실패:
    - 404 NotFoundError: 비활성 또는 존재하지 않는 아이돌
    """
    stmt = (
        select(IdolProfile, Profile)
        .join(Profile, Profile.id == IdolProfile.id)
        .where(and_(IdolProfile.id == idol_id, *_active_idol_filter()))
    )
    row = (await session.execute(stmt)).first()
    if row is None:
        raise NotFoundError("아이돌을 찾을 수 없습니다.")
    idol, _profile = row

    # 응원 팬 수 (활성 구독만).
    fan_count = await session.scalar(
        select(func.count())
        .select_from(Subscription)
        .where(
            Subscription.idol_id == idol_id,
            Subscription.unsubscribed_at.is_(None),
        )
    )

    # 본인 응원 여부. 본인이 그 아이돌 본인이면 항상 False.
    is_subscribed = False
    if viewer_id != idol_id:
        sub = await session.scalar(
            select(Subscription).where(
                Subscription.fan_id == viewer_id,
                Subscription.idol_id == idol_id,
                Subscription.unsubscribed_at.is_(None),
            )
        )
        is_subscribed = sub is not None

    return IdolDetailResponse(
        id=idol.id,
        stage_name=idol.stage_name,
        bio=idol.bio,
        thumbnail_url=idol.thumbnail_url,
        activated_at=idol.activated_at,
        fan_count=fan_count or 0,
        is_subscribed=is_subscribed,
    )


# ============================================================
# 내부 매퍼
# ============================================================


def _to_list_item(idol: IdolProfile) -> IdolListItem:
    bio_summary: str | None = None
    if idol.bio:
        bio_summary = (
            idol.bio[:_BIO_SUMMARY_LEN] + "…" if len(idol.bio) > _BIO_SUMMARY_LEN else idol.bio
        )

    return IdolListItem(
        id=idol.id,
        stage_name=idol.stage_name,
        bio_summary=bio_summary,
        thumbnail_url=idol.thumbnail_url,
        activated_at=idol.activated_at,
    )
