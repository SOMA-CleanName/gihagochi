"""F-035 / F-036 / F-038 admin — 서비스 레이어.

라우터는 얇게 — 파라미터 추출 + service 호출만. 비즈 로직 / DB 트랜잭션은 모두 여기.

공개 인터페이스 (다른 피처가 호출): 없음. admin은 leaf 슬라이스.
SELECT는 어드민 웹의 Server Component가 supabase server client + admin RLS로 직접 처리.
"""

from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import ConflictError, NotFoundError, ValidationError
from app.features.admin.schemas import IdolApplicationDetail, UserDetail
from app.shared.enums import SignupApplicationStatus, UserRole, UserStatus
from app.shared.models import IdolProfile, IdolSignupApplication, Profile

# ============================================================
# F-035 아이돌 가입 신청 승인
# ============================================================


async def approve_idol_application(
    session: AsyncSession,
    application_id: UUID,
    admin_user_id: UUID,
) -> IdolApplicationDetail:
    """승인 트랜잭션 — applications UPDATE + idol_profiles INSERT + profiles UPDATE.

    실패:
    - 404 NotFoundError: 해당 신청 없음
    - 409 ConflictError: 이미 처리됨 (status != pending) / stage_name UNIQUE 충돌
    """
    application = await session.scalar(
        select(IdolSignupApplication).where(IdolSignupApplication.id == application_id)
    )
    if application is None:
        raise NotFoundError("아이돌 가입 신청을 찾을 수 없습니다.")

    # 동시 처리 충돌 방지 — pending이 아닐 때 즉시 409.
    if application.status != SignupApplicationStatus.PENDING:
        raise ConflictError("이미 처리된 신청입니다.")

    now = datetime.now(UTC)

    # 1. applications UPDATE — conditional WHERE로 동시 승인/반려 race 차단.
    result = await session.execute(
        update(IdolSignupApplication)
        .where(
            IdolSignupApplication.id == application_id,
            IdolSignupApplication.status == SignupApplicationStatus.PENDING,
        )
        .values(
            status=SignupApplicationStatus.APPROVED,
            handled_by=admin_user_id,
            handled_at=now,
            updated_at=now,
        )
    )
    if result.rowcount == 0:
        # 위 scalar 조회와 UPDATE 사이에 다른 관리자가 먼저 처리한 케이스.
        raise ConflictError("이미 처리된 신청입니다.")

    # 2. idol_profiles INSERT — stage_name UNIQUE 충돌 시 IntegrityError → 409.
    idol_profile = IdolProfile(
        id=application.user_id,
        signup_application_id=application.id,
        stage_name=application.stage_name,
        bio=application.bio,
    )
    session.add(idol_profile)

    # 3. profiles role UPDATE.
    await session.execute(
        update(Profile)
        .where(Profile.id == application.user_id)
        .values(role=UserRole.IDOL, updated_at=now)
    )

    try:
        await session.flush()
    except IntegrityError as e:
        # stage_name UNIQUE 충돌 — 신청자에게 다른 활동명 안내 필요.
        await session.rollback()
        raise ConflictError("활동명이 이미 사용 중입니다.") from e

    await session.refresh(application)
    return _to_application_detail(application)


# ============================================================
# F-035 아이돌 가입 신청 반려
# ============================================================


async def reject_idol_application(
    session: AsyncSession,
    application_id: UUID,
    admin_user_id: UUID,
    rejection_reason: str,
) -> IdolApplicationDetail:
    """반려 — applications UPDATE만. rejection_reason은 schema에서 길이 검증됨.

    실패:
    - 404 NotFoundError: 해당 신청 없음
    - 409 ConflictError: 이미 처리됨
    """
    application = await session.scalar(
        select(IdolSignupApplication).where(IdolSignupApplication.id == application_id)
    )
    if application is None:
        raise NotFoundError("아이돌 가입 신청을 찾을 수 없습니다.")

    if application.status != SignupApplicationStatus.PENDING:
        raise ConflictError("이미 처리된 신청입니다.")

    now = datetime.now(UTC)
    result = await session.execute(
        update(IdolSignupApplication)
        .where(
            IdolSignupApplication.id == application_id,
            IdolSignupApplication.status == SignupApplicationStatus.PENDING,
        )
        .values(
            status=SignupApplicationStatus.REJECTED,
            rejection_reason=rejection_reason,
            handled_by=admin_user_id,
            handled_at=now,
            updated_at=now,
        )
    )
    if result.rowcount == 0:
        raise ConflictError("이미 처리된 신청입니다.")

    await session.refresh(application)
    return _to_application_detail(application)


# ============================================================
# F-038 사용자 정지
# ============================================================


async def suspend_user(
    session: AsyncSession,
    target_user_id: UUID,
    admin_user_id: UUID,
    suspend_reason: str,
) -> UserDetail:
    """사용자 정지 — profiles.status='suspended' + suspended_at + suspend_reason.

    실패:
    - 400 ValidationError: 자기 자신 정지 시도
    - 404 NotFoundError: 해당 사용자 없음
    - 400 ValidationError: 이미 정지된 사용자
    """
    if target_user_id == admin_user_id:
        raise ValidationError("자기 자신은 정지할 수 없습니다.")

    profile = await session.scalar(select(Profile).where(Profile.id == target_user_id))
    if profile is None:
        raise NotFoundError("사용자를 찾을 수 없습니다.")

    if profile.status == UserStatus.SUSPENDED:
        raise ValidationError("이미 정지된 사용자입니다.")

    now = datetime.now(UTC)
    await session.execute(
        update(Profile)
        .where(Profile.id == target_user_id)
        .values(
            status=UserStatus.SUSPENDED,
            suspended_at=now,
            suspend_reason=suspend_reason,
            updated_at=now,
        )
    )
    await session.flush()
    await session.refresh(profile)
    return _to_user_detail(profile)


# ============================================================
# F-038 사용자 정지 해제
# ============================================================


async def unsuspend_user(
    session: AsyncSession,
    target_user_id: UUID,
) -> UserDetail:
    """사용자 정지 해제 — status='active' + suspended_at/suspend_reason NULL.

    실패:
    - 404 NotFoundError: 해당 사용자 없음
    - 400 ValidationError: 정지 상태가 아닌 사용자
    """
    profile = await session.scalar(select(Profile).where(Profile.id == target_user_id))
    if profile is None:
        raise NotFoundError("사용자를 찾을 수 없습니다.")

    if profile.status != UserStatus.SUSPENDED:
        raise ValidationError("정지 상태가 아닌 사용자입니다.")

    now = datetime.now(UTC)
    await session.execute(
        update(Profile)
        .where(Profile.id == target_user_id)
        .values(
            status=UserStatus.ACTIVE,
            suspended_at=None,
            suspend_reason=None,
            updated_at=now,
        )
    )
    await session.flush()
    await session.refresh(profile)
    return _to_user_detail(profile)


# ============================================================
# 내부 매퍼
# ============================================================


def _to_application_detail(app: IdolSignupApplication) -> IdolApplicationDetail:
    return IdolApplicationDetail(
        id=app.id,
        user_id=app.user_id,
        stage_name=app.stage_name,
        bio=app.bio,
        application_note=app.application_note,
        status=app.status,
        handled_by=app.handled_by,
        handled_at=app.handled_at,
        rejection_reason=app.rejection_reason,
        created_at=app.created_at,
        updated_at=app.updated_at,
    )


def _to_user_detail(profile: Profile) -> UserDetail:
    return UserDetail(
        id=profile.id,
        role=profile.role,
        status=profile.status,
        display_name=profile.display_name,
        avatar_url=profile.avatar_url,
        suspended_at=profile.suspended_at,
        suspend_reason=profile.suspend_reason,
        created_at=profile.created_at,
        updated_at=profile.updated_at,
    )
