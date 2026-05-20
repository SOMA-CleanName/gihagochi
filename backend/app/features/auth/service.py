"""F-001~F-006 auth — 서비스 레이어.

라우터는 얇게. 비즈니스 로직 / DB 접근은 모두 여기.

공개 인터페이스 (다른 피처가 호출 가능):
- `get_profile_summary(session, user_id)` — 프로필 요약 (없으면 None)
- `has_pending_idol_application(session, user_id)` — 아이돌 신청 pending 여부
"""

from uuid import UUID

from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import ConflictError, ValidationError
from app.features.auth.schemas import (
    AgreementsInput,
    IdolApplicationSummary,
    MeResponse,
    ProfileSummary,
    SignupRequest,
    SignupResponse,
    TermsCurrentResponse,
)
from app.shared.enums import AgreementType, UserRole, UserStatus
from app.shared.models import IdolSignupApplication, Profile, TermsAgreement

# 현재 활성 약관 version. 갱신 시 새 version 문자열 + 클라이언트 재배포 필요.
# 별도 DB 테이블 / settings 안 쓰는 이유: 약관 본문은 admin 웹의 정적 페이지에서 관리하고
# 백엔드는 version 문자열로만 매칭. 단순화 우선.
_CURRENT_TERMS_VERSIONS: dict[AgreementType, str] = {
    AgreementType.TOS: "v1",
    AgreementType.PRIVACY: "v1",
    AgreementType.MARKETING: "v1",
}


# ============================================================
# /auth/signup
# ============================================================


async def create_signup(
    session: AsyncSession,
    supabase_user_id: UUID,
    req: SignupRequest,
) -> SignupResponse:
    """가입 트랜잭션: profile + (선택)아이돌 신청 + 약관 동의를 한 번에 생성.

    실패:
    - 409 ConflictError: 동일 user_id로 이미 profile 존재
    - 422 ValidationError: as=idol인데 stage_name 누락 / 약관 version mismatch / tos|privacy 미동의
    """
    # 1. 중복 가입 차단.
    existing = await session.scalar(select(Profile).where(Profile.id == supabase_user_id))
    if existing is not None:
        raise ConflictError("이미 가입된 사용자입니다.")

    # 2. as=idol일 때 추가 필드 검증.
    if req.as_ == "idol" and not req.stage_name:
        raise ValidationError("아이돌 가입은 stage_name이 필수입니다.")

    # 3. 약관 검증 — tos/privacy 필수 동의 + 모든 version 매칭.
    _validate_agreements(req.agreements)

    # 4. profile INSERT — 옵션 C: 아이돌 지원자도 일단 fan/active.
    profile = Profile(
        id=supabase_user_id,
        role=UserRole.FAN,
        status=UserStatus.ACTIVE,
        display_name=req.display_name,
    )
    session.add(profile)

    # 5. 아이돌이면 신청 row 추가.
    application: IdolSignupApplication | None = None
    if req.as_ == "idol":
        # stage_name None은 위에서 차단됨 — 타입 좁히기.
        assert req.stage_name is not None
        application = IdolSignupApplication(
            user_id=supabase_user_id,
            stage_name=req.stage_name,
            bio=req.bio,
            application_note=req.application_note,
        )
        session.add(application)

    # 6. 약관 동의 row들 (tos/privacy 필수, marketing은 agreed=True일 때만).
    for agreement_type, agreement_input in (
        (AgreementType.TOS, req.agreements.tos),
        (AgreementType.PRIVACY, req.agreements.privacy),
    ):
        session.add(
            TermsAgreement(
                user_id=supabase_user_id,
                type=agreement_type,
                version=agreement_input.version,
            )
        )
    if req.agreements.marketing is not None and req.agreements.marketing.agreed:
        session.add(
            TermsAgreement(
                user_id=supabase_user_id,
                type=AgreementType.MARKETING,
                version=req.agreements.marketing.version,
            )
        )

    # 7. PK / server_default 채우기 위해 flush. commit은 get_session 의존성이 처리.
    await session.flush()
    if application is not None:
        await session.refresh(application)

    return SignupResponse(
        profile=_to_profile_summary(profile),
        idol_application=_to_application_summary(application) if application else None,
    )


def _validate_agreements(agreements: AgreementsInput) -> None:
    """약관 검증.

    - tos/privacy: agreed=True 강제 (스키마 기본 True지만 명시적 false 차단)
    - 모든 type의 version은 _CURRENT_TERMS_VERSIONS와 일치해야 함
    """
    if not agreements.tos.agreed or not agreements.privacy.agreed:
        raise ValidationError("서비스 이용약관과 개인정보 처리방침 동의가 필요합니다.")

    expected_tos = _CURRENT_TERMS_VERSIONS[AgreementType.TOS]
    expected_privacy = _CURRENT_TERMS_VERSIONS[AgreementType.PRIVACY]
    expected_marketing = _CURRENT_TERMS_VERSIONS[AgreementType.MARKETING]

    if agreements.tos.version != expected_tos:
        raise ValidationError(f"약관 version mismatch: tos는 {expected_tos}여야 합니다.")
    if agreements.privacy.version != expected_privacy:
        raise ValidationError(f"약관 version mismatch: privacy는 {expected_privacy}여야 합니다.")
    if agreements.marketing is not None and agreements.marketing.version != expected_marketing:
        raise ValidationError(f"약관 version mismatch: marketing은 {expected_marketing}여야 합니다.")


# ============================================================
# /auth/me
# ============================================================


async def get_me(session: AsyncSession, user_id: UUID) -> MeResponse:
    """현재 사용자 프로필 + 최신 아이돌 신청 상태.

    user_id는 AuthedUser 의존성에서 이미 profile 존재 확인됨.
    """
    profile = await session.scalar(select(Profile).where(Profile.id == user_id))
    # AuthedUser를 통과했다면 profile은 반드시 있음. 안전망으로 한 번 더.
    assert profile is not None, "AuthedUser 의존성 통과 시 profile 존재 보장"

    latest_app = await _get_latest_idol_application(session, user_id)
    return MeResponse(
        profile=_to_profile_summary(profile),
        latest_idol_application=_to_application_summary(latest_app) if latest_app else None,
    )


async def _get_latest_idol_application(
    session: AsyncSession, user_id: UUID
) -> IdolSignupApplication | None:
    """가장 최근에 생성된 신청 row 1개. 없으면 None."""
    return await session.scalar(
        select(IdolSignupApplication)
        .where(IdolSignupApplication.user_id == user_id)
        .order_by(desc(IdolSignupApplication.created_at))
        .limit(1)
    )


# ============================================================
# /auth/terms/current
# ============================================================


def get_current_terms() -> TermsCurrentResponse:
    """현재 활성 약관 version 목록. 비인증 호출 OK라 동기 함수."""
    return TermsCurrentResponse(
        tos=_CURRENT_TERMS_VERSIONS[AgreementType.TOS],
        privacy=_CURRENT_TERMS_VERSIONS[AgreementType.PRIVACY],
        marketing=_CURRENT_TERMS_VERSIONS[AgreementType.MARKETING],
    )


# ============================================================
# 공개 인터페이스 — 다른 피처가 호출
# ============================================================


async def get_profile_summary(
    session: AsyncSession, user_id: UUID
) -> ProfileSummary | None:
    """프로필 요약. 없으면 None.

    다른 피처가 사용자 표시용으로 호출.
    """
    profile = await session.scalar(select(Profile).where(Profile.id == user_id))
    return _to_profile_summary(profile) if profile else None


async def has_pending_idol_application(session: AsyncSession, user_id: UUID) -> bool:
    """가장 최신 아이돌 신청이 pending 상태인지.

    features/admin이 승인 처리 시 / UI에서 신청자 표시용.
    """
    from app.shared.enums import SignupApplicationStatus  # 순환 import 회피 (모듈 끝에서 import)

    latest = await _get_latest_idol_application(session, user_id)
    return latest is not None and latest.status == SignupApplicationStatus.PENDING


# ============================================================
# 내부 매퍼
# ============================================================


def _to_profile_summary(profile: Profile) -> ProfileSummary:
    return ProfileSummary(
        id=profile.id,
        role=profile.role,
        status=profile.status,
        display_name=profile.display_name,
        avatar_url=profile.avatar_url,
    )


def _to_application_summary(app: IdolSignupApplication) -> IdolApplicationSummary:
    return IdolApplicationSummary(
        id=app.id,
        status=app.status,
        stage_name=app.stage_name,
        created_at=app.created_at,
        rejection_reason=app.rejection_reason,
    )
