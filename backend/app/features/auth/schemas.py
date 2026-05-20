"""F-001~F-006 auth — Pydantic 스키마 (API 입출력).

요청/응답 형태는 SPEC.md의 'API' 섹션과 1:1 매핑.
"""

from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from app.shared.enums import SignupApplicationStatus, UserRole, UserStatus


# ============================================================
# /auth/signup — 요청
# ============================================================


class AgreementInput(BaseModel):
    """약관 1건의 사용자 응답. version만 받고 동의 여부는 marketing만 false 가능."""

    version: str
    # tos/privacy는 미체크 시 클라가 요청 자체를 막아야 하므로 기본 True.
    # marketing은 사용자가 명시적으로 false 보낼 수 있어 별도 처리.
    agreed: bool = True


class AgreementsInput(BaseModel):
    """가입 시 동의 항목 묶음. tos/privacy 필수, marketing 선택."""

    tos: AgreementInput
    privacy: AgreementInput
    marketing: AgreementInput | None = None


class SignupRequest(BaseModel):
    """POST /auth/signup 요청 본문 (옵션 C — 팬/아이돌 선택)."""

    model_config = ConfigDict(populate_by_name=True)

    # Python 예약어 `as` 회피 — alias로 외부 노출.
    as_: Literal["fan", "idol"] = Field(alias="as")
    display_name: str = Field(min_length=1, max_length=30)
    # as=idol 일 때만 필수. validator로 강제하기보다 service에서 확인 (단순함 우선).
    stage_name: str | None = Field(default=None, min_length=1, max_length=30)
    bio: str | None = Field(default=None, max_length=500)
    application_note: str | None = Field(default=None, max_length=1000)
    agreements: AgreementsInput


# ============================================================
# 응답 — 공통 요약
# ============================================================


class ProfileSummary(BaseModel):
    """프로필 요약. /auth/me 응답 + 다른 피처가 호출 가능한 공개 인터페이스 반환형."""

    id: UUID
    role: UserRole
    status: UserStatus
    display_name: str
    avatar_url: str | None


class IdolApplicationSummary(BaseModel):
    """아이돌 신청 1건 요약. 가장 최신 row 1개만 반환."""

    id: UUID
    status: SignupApplicationStatus
    stage_name: str
    created_at: datetime
    rejection_reason: str | None


# ============================================================
# /auth/signup — 응답
# ============================================================


class SignupResponse(BaseModel):
    """POST /auth/signup 응답."""

    profile: ProfileSummary
    # as=idol 일 때만 채워짐. as=fan 이면 None.
    idol_application: IdolApplicationSummary | None


# ============================================================
# /auth/me — 응답
# ============================================================


class MeResponse(BaseModel):
    """GET /auth/me 응답. profile + 최신 아이돌 신청 상태(있으면)."""

    profile: ProfileSummary
    latest_idol_application: IdolApplicationSummary | None


# ============================================================
# /auth/terms/current — 응답
# ============================================================


class TermsCurrentResponse(BaseModel):
    """현재 활성 약관 version 목록. 가입 화면이 사용."""

    tos: str
    privacy: str
    marketing: str
