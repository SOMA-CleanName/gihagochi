"""F-035 / F-036 / F-038 admin — 라우터/서비스 테스트.

전략:
- 라우터는 인증 가드 위주 (401: 미인증 / 403: 비-admin role)
- 서비스는 단순 분기 (404 NotFoundError / 400 ValidationError — uuid4 가짜로 검증)

DB INSERT가 필요한 정상 케이스(승인 트랜잭션 골든 패스)는 수동 시나리오에 위임.
make_fresh_user 등 통합 fixture가 필요한 케이스는 향후 추가.
"""

from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import ConflictError, NotFoundError, ValidationError
from app.features.admin import service

# ============================================================
# 라우터 — 인증 가드 (401)
# ============================================================


@pytest.mark.asyncio
async def test_approve_requires_auth(client: AsyncClient) -> None:
    """승인은 AdminUser 필요 — 헤더 없으면 401."""
    response = await client.post(f"/admin/idol-applications/{uuid4()}/approve")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_reject_requires_auth(client: AsyncClient) -> None:
    """반려도 401."""
    response = await client.post(
        f"/admin/idol-applications/{uuid4()}/reject",
        json={"rejection_reason": "테스트 사유"},
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_suspend_requires_auth(client: AsyncClient) -> None:
    """정지도 401."""
    response = await client.post(
        f"/admin/users/{uuid4()}/suspend",
        json={"suspend_reason": "테스트 사유"},
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_unsuspend_requires_auth(client: AsyncClient) -> None:
    """해제도 401."""
    response = await client.post(f"/admin/users/{uuid4()}/unsuspend")
    assert response.status_code == 401


# rejection_reason / suspend_reason 빈 문자열 → 422 (Pydantic min_length=1) 검증은
# AdminUser 의존성이 먼저 profiles 조회를 트리거해 CI(DB 없음)에서 실패. 실제 admin
# 사용자가 필요한 통합 테스트로 향후 추가.


# ============================================================
# 서비스 — 비즈 룰 분기 (integration: 실제 dev DB session 필요)
# ============================================================


@pytest.mark.integration
@pytest.mark.asyncio
async def test_approve_unknown_application_raises_not_found(
    session: AsyncSession,
) -> None:
    """존재하지 않는 application id → NotFoundError."""
    with pytest.raises(NotFoundError):
        await service.approve_idol_application(session, uuid4(), uuid4())


@pytest.mark.integration
@pytest.mark.asyncio
async def test_reject_unknown_application_raises_not_found(
    session: AsyncSession,
) -> None:
    """존재하지 않는 application id → NotFoundError."""
    with pytest.raises(NotFoundError):
        await service.reject_idol_application(session, uuid4(), uuid4(), "사유")


@pytest.mark.integration
@pytest.mark.asyncio
async def test_suspend_self_raises_validation(session: AsyncSession) -> None:
    """target == admin → ValidationError (자기 자신 정지 차단)."""
    same_id = uuid4()
    with pytest.raises(ValidationError):
        await service.suspend_user(session, same_id, same_id, "사유")


@pytest.mark.integration
@pytest.mark.asyncio
async def test_suspend_unknown_user_raises_not_found(session: AsyncSession) -> None:
    """존재하지 않는 user id → NotFoundError."""
    with pytest.raises(NotFoundError):
        await service.suspend_user(session, uuid4(), uuid4(), "사유")


@pytest.mark.integration
@pytest.mark.asyncio
async def test_unsuspend_unknown_user_raises_not_found(session: AsyncSession) -> None:
    """존재하지 않는 user id → NotFoundError."""
    with pytest.raises(NotFoundError):
        await service.unsuspend_user(session, uuid4())


# ConflictError 분기(이미 처리된 신청)는 실제 INSERT가 필요해서 수동/통합 테스트로 위임.
# 본 파일에서는 NotFoundError 경로만 단위 커버.
_ = ConflictError  # noqa: F841  — import 유지 (향후 통합 테스트 작성 시 사용)
