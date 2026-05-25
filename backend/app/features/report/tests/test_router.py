"""F-033 / F-037 report — 라우터/서비스/스키마 테스트.

- 라우터: 인증 가드 (401), role 가드 간접 (FanUser/AdminUser는 미인증 시 401)
- 스키마: Pydantic validator (reason 길이, action enum)
- 서비스: integration (dev DB 필요) — non-integration은 분기 검증만
"""

from uuid import uuid4

import pytest
from httpx import AsyncClient

# ============================================================
# 라우터 — 인증 가드 (401)
# ============================================================


@pytest.mark.asyncio
async def test_create_report_requires_auth(client: AsyncClient) -> None:
    response = await client.post(
        "/reports",
        json={"message_id": str(uuid4()), "reason": "부적절한 메시지입니다."},
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_list_pending_reports_requires_auth(client: AsyncClient) -> None:
    response = await client.get("/admin/reports")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_resolve_report_requires_auth(client: AsyncClient) -> None:
    response = await client.post(
        f"/admin/reports/{uuid4()}/resolve",
        json={"resolution_action": "warned"},
    )
    assert response.status_code == 401


# ============================================================
# 스키마 — Pydantic validator
# ============================================================


def test_report_create_reason_too_short_rejected() -> None:
    from pydantic import ValidationError as PydValidationError

    from app.features.report.schemas import ReportCreateRequest

    with pytest.raises(PydValidationError):
        ReportCreateRequest(message_id=uuid4(), reason="짧음")  # 4자 < 10


def test_report_create_reason_too_long_rejected() -> None:
    from pydantic import ValidationError as PydValidationError

    from app.features.report.schemas import ReportCreateRequest

    with pytest.raises(PydValidationError):
        ReportCreateRequest(message_id=uuid4(), reason="가" * 501)


def test_report_create_reason_min_length_ok() -> None:
    from app.features.report.schemas import ReportCreateRequest

    req = ReportCreateRequest(message_id=uuid4(), reason="가" * 10)
    assert len(req.reason) == 10


def test_report_resolve_action_enum_validated() -> None:
    from pydantic import ValidationError as PydValidationError

    from app.features.report.schemas import ReportResolveRequest

    # 유효한 액션
    ReportResolveRequest(resolution_action="warned")  # type: ignore[arg-type]
    # 유효하지 않은 액션
    with pytest.raises(PydValidationError):
        ReportResolveRequest(resolution_action="invalid_action")  # type: ignore[arg-type]


def test_report_resolve_note_too_long_rejected() -> None:
    from pydantic import ValidationError as PydValidationError

    from app.features.report.schemas import ReportResolveRequest

    with pytest.raises(PydValidationError):
        ReportResolveRequest(
            resolution_action="warned",  # type: ignore[arg-type]
            resolution_note="가" * 501,
        )


# ============================================================
# 서비스 — 분기 (integration: dev DB 필요)
# ============================================================


@pytest.mark.integration
@pytest.mark.asyncio
async def test_get_warned_count_zero_when_no_reports(session) -> None:  # noqa: ANN001
    from app.features.report import service

    count = await service.get_warned_count_for_user(session, uuid4())
    assert count == 0


@pytest.mark.integration
@pytest.mark.asyncio
async def test_create_report_message_not_found(session) -> None:  # noqa: ANN001
    from app.core.errors import NotFoundError
    from app.features.report import service

    with pytest.raises(NotFoundError):
        await service.create_report(
            session,
            reporter_id=uuid4(),
            message_id=uuid4(),
            reason="존재하지 않는 메시지 테스트입니다.",
        )


@pytest.mark.integration
@pytest.mark.asyncio
async def test_resolve_report_not_found(session) -> None:  # noqa: ANN001
    from app.core.errors import NotFoundError
    from app.features.report import service
    from app.features.report.schemas import ReportResolveRequest

    with pytest.raises(NotFoundError):
        await service.resolve_report(
            session,
            report_id=uuid4(),
            admin_user_id=uuid4(),
            request=ReportResolveRequest(
                resolution_action="dismissed",  # type: ignore[arg-type]
            ),
        )
