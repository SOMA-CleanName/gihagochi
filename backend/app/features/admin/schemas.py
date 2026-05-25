"""F-035 / F-036 / F-038 admin — Pydantic 스키마 (API 입출력).

요청/응답 형태는 SPEC.md의 'API' 섹션과 1:1 매핑.
SELECT(리스트/검색)는 어드민 웹이 Server Component로 직접 처리하므로 본 모듈은 mutation 응답만.
"""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.shared.enums import SignupApplicationStatus, UserRole, UserStatus

# ============================================================
# 공통 detail 응답
# ============================================================


class IdolApplicationDetail(BaseModel):
    """idol_signup_applications 단건 응답. 승인/반려 후 갱신된 row를 그대로 반환."""

    id: UUID
    user_id: UUID
    stage_name: str
    bio: str | None
    application_note: str | None
    status: SignupApplicationStatus
    handled_by: UUID | None
    handled_at: datetime | None
    rejection_reason: str | None
    created_at: datetime
    updated_at: datetime


class UserDetail(BaseModel):
    """profiles 단건 응답. 정지/해제 후 갱신된 row를 그대로 반환."""

    id: UUID
    role: UserRole
    status: UserStatus
    display_name: str
    avatar_url: str | None
    suspended_at: datetime | None
    suspend_reason: str | None
    created_at: datetime
    updated_at: datetime


# ============================================================
# /admin/idol-applications/{id}/reject — 요청
# ============================================================


class RejectApplicationRequest(BaseModel):
    """반려 사유는 필수. UX상 1글자만 입력하지 않게 최소 1, 최대 500자."""

    rejection_reason: str = Field(min_length=1, max_length=500)


# ============================================================
# /admin/users/{id}/suspend — 요청
# ============================================================


class SuspendUserRequest(BaseModel):
    """정지 사유는 필수. profiles.suspend_reason에 그대로 저장."""

    suspend_reason: str = Field(min_length=1, max_length=500)
