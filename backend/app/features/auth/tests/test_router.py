"""F-001~F-006 auth — 라우터/서비스 테스트.

전략:
- 라우터는 인증 가드 위주 (실제 DB INSERT는 conftest session과 격리 안 됨)
- 비즈니스 룰은 service 레이어 직접 호출 (conftest의 rollback session 사용)
"""

from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import ConflictError, ValidationError
from app.features.auth import service
from app.features.auth.schemas import (
    AgreementInput,
    AgreementsInput,
    SignupRequest,
)
from app.shared.enums import (
    AgreementType,
    SignupApplicationStatus,
    UserRole,
    UserStatus,
)
from app.shared.models import TermsAgreement

# ============================================================
# 라우터 — 인증 가드
# ============================================================


@pytest.mark.asyncio
async def test_signup_requires_auth(client: AsyncClient) -> None:
    """/auth/signup은 PendingAuthUser 필요 — 헤더 없으면 401."""
    response = await client.post("/auth/signup", json={"as": "fan"})
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_me_requires_auth(client: AsyncClient) -> None:
    """/auth/me는 AuthedUser 필요 — 헤더 없으면 401."""
    response = await client.get("/auth/me")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_terms_current_is_public(client: AsyncClient) -> None:
    """/auth/terms/current는 비인증 호출 OK — 200 + version 필드들."""
    response = await client.get("/auth/terms/current")
    assert response.status_code == 200
    body = response.json()
    assert "tos" in body and "privacy" in body and "marketing" in body


# ============================================================
# 서비스 — 비즈니스 룰
# ============================================================


def _valid_agreements() -> AgreementsInput:
    """현재 활성 version에 맞춘 동의 입력. 테스트 헬퍼."""
    terms = service.get_current_terms()
    return AgreementsInput(
        tos=AgreementInput(version=terms.tos),
        privacy=AgreementInput(version=terms.privacy),
        marketing=AgreementInput(version=terms.marketing, agreed=False),
    )


@pytest.mark.integration
@pytest.mark.asyncio
async def test_signup_fan_creates_profile_and_terms(session: AsyncSession, make_fresh_user) -> None:
    """팬 가입 정상 케이스 → profile + 약관 2건(tos, privacy) 생성."""
    user_id = make_fresh_user()
    req = SignupRequest(
        as_="fan",  # type: ignore[call-arg]
        display_name="테스트팬",
        agreements=_valid_agreements(),
    )

    result = await service.create_signup(session, user_id, req)

    assert result.profile.role == UserRole.FAN
    assert result.profile.status == UserStatus.ACTIVE
    assert result.profile.display_name == "테스트팬"
    assert result.idol_application is None

    # 약관은 tos/privacy 2건 (marketing은 agreed=False라 INSERT 안 됨).
    rows = await session.scalars(select(TermsAgreement).where(TermsAgreement.user_id == user_id))
    types = {r.type for r in rows}
    assert types == {AgreementType.TOS, AgreementType.PRIVACY}


@pytest.mark.integration
@pytest.mark.asyncio
async def test_signup_idol_creates_application(session: AsyncSession, make_fresh_user) -> None:
    """아이돌 가입 → profile은 fan/active로 생성 + 신청 row 1개 pending."""
    user_id = make_fresh_user()
    req = SignupRequest(
        as_="idol",  # type: ignore[call-arg]
        display_name="테스트아이돌",
        stage_name="스테이지명",
        bio="짧은 소개",
        agreements=_valid_agreements(),
    )

    result = await service.create_signup(session, user_id, req)

    # 옵션 C 핵심 — 아이돌도 일단 fan/active. 승인 후에야 role 변경.
    assert result.profile.role == UserRole.FAN
    assert result.profile.status == UserStatus.ACTIVE
    assert result.idol_application is not None
    assert result.idol_application.status == SignupApplicationStatus.PENDING
    assert result.idol_application.stage_name == "스테이지명"


@pytest.mark.integration
@pytest.mark.asyncio
async def test_signup_idol_without_stage_name_raises(session: AsyncSession) -> None:
    """아이돌 가입에 stage_name 누락 → ValidationError(422)."""
    user_id = uuid4()
    req = SignupRequest(
        as_="idol",  # type: ignore[call-arg]
        display_name="활동명없음",
        agreements=_valid_agreements(),
    )
    with pytest.raises(ValidationError):
        await service.create_signup(session, user_id, req)


@pytest.mark.integration
@pytest.mark.asyncio
async def test_signup_duplicate_raises_conflict(session: AsyncSession, make_fresh_user) -> None:
    """동일 user_id 두 번째 호출 → ConflictError(409)."""
    user_id = make_fresh_user()
    req = SignupRequest(
        as_="fan",  # type: ignore[call-arg]
        display_name="중복테스트",
        agreements=_valid_agreements(),
    )
    await service.create_signup(session, user_id, req)
    await session.flush()

    with pytest.raises(ConflictError):
        await service.create_signup(session, user_id, req)


@pytest.mark.integration
@pytest.mark.asyncio
async def test_signup_tos_disagreed_raises(session: AsyncSession) -> None:
    """tos.agreed=False → ValidationError. privacy도 동일."""
    user_id = uuid4()
    terms = service.get_current_terms()
    req = SignupRequest(
        as_="fan",  # type: ignore[call-arg]
        display_name="미동의",
        agreements=AgreementsInput(
            tos=AgreementInput(version=terms.tos, agreed=False),
            privacy=AgreementInput(version=terms.privacy, agreed=True),
        ),
    )
    with pytest.raises(ValidationError):
        await service.create_signup(session, user_id, req)


@pytest.mark.integration
@pytest.mark.asyncio
async def test_signup_version_mismatch_raises(session: AsyncSession) -> None:
    """약관 version이 현재 활성과 다르면 ValidationError."""
    user_id = uuid4()
    terms = service.get_current_terms()
    req = SignupRequest(
        as_="fan",  # type: ignore[call-arg]
        display_name="버전불일치",
        agreements=AgreementsInput(
            tos=AgreementInput(version="v999"),
            privacy=AgreementInput(version=terms.privacy),
        ),
    )
    with pytest.raises(ValidationError):
        await service.create_signup(session, user_id, req)


@pytest.mark.integration
@pytest.mark.asyncio
async def test_get_me_returns_profile_with_latest_application(
    session: AsyncSession, make_fresh_user
) -> None:
    """가입 후 get_me는 profile + 최신 idol application 반환."""
    user_id = make_fresh_user()
    req = SignupRequest(
        as_="idol",  # type: ignore[call-arg]
        display_name="조회테스트",
        stage_name="조회스테이지",
        agreements=_valid_agreements(),
    )
    await service.create_signup(session, user_id, req)
    await session.flush()

    result = await service.get_me(session, user_id)

    assert result.profile.display_name == "조회테스트"
    assert result.latest_idol_application is not None
    assert result.latest_idol_application.stage_name == "조회스테이지"


@pytest.mark.integration
@pytest.mark.asyncio
async def test_has_pending_idol_application(session: AsyncSession, make_fresh_user) -> None:
    """공개 인터페이스 — pending 신청 있을 때 True, 팬만일 때 False."""
    idol_id = make_fresh_user()
    fan_id = make_fresh_user()
    await service.create_signup(
        session,
        idol_id,
        SignupRequest(
            as_="idol",  # type: ignore[call-arg]
            display_name="아이돌",
            stage_name="아이돌무대",
            agreements=_valid_agreements(),
        ),
    )
    await service.create_signup(
        session,
        fan_id,
        SignupRequest(
            as_="fan",  # type: ignore[call-arg]
            display_name="팬",
            agreements=_valid_agreements(),
        ),
    )
    await session.flush()

    assert await service.has_pending_idol_application(session, idol_id) is True
    assert await service.has_pending_idol_application(session, fan_id) is False


@pytest.mark.integration
@pytest.mark.asyncio
async def test_terms_agreements_marketing_only_when_agreed(
    session: AsyncSession, make_fresh_user
) -> None:
    """marketing.agreed=True일 때만 terms_agreements에 INSERT."""
    user_with_marketing = make_fresh_user()
    user_without_marketing = make_fresh_user()
    terms = service.get_current_terms()

    # marketing=true
    await service.create_signup(
        session,
        user_with_marketing,
        SignupRequest(
            as_="fan",  # type: ignore[call-arg]
            display_name="마케팅동의",
            agreements=AgreementsInput(
                tos=AgreementInput(version=terms.tos),
                privacy=AgreementInput(version=terms.privacy),
                marketing=AgreementInput(version=terms.marketing, agreed=True),
            ),
        ),
    )
    # marketing=false
    await service.create_signup(
        session,
        user_without_marketing,
        SignupRequest(
            as_="fan",  # type: ignore[call-arg]
            display_name="마케팅거부",
            agreements=AgreementsInput(
                tos=AgreementInput(version=terms.tos),
                privacy=AgreementInput(version=terms.privacy),
                marketing=AgreementInput(version=terms.marketing, agreed=False),
            ),
        ),
    )
    await session.flush()

    with_rows = (
        await session.scalars(
            select(TermsAgreement).where(TermsAgreement.user_id == user_with_marketing)
        )
    ).all()
    without_rows = (
        await session.scalars(
            select(TermsAgreement).where(TermsAgreement.user_id == user_without_marketing)
        )
    ).all()

    assert AgreementType.MARKETING in {r.type for r in with_rows}
    assert AgreementType.MARKETING not in {r.type for r in without_rows}
