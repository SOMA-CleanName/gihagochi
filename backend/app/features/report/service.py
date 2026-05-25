"""F-033 / F-037 report — 서비스 레이어.

reports 테이블 owner. resolve 시 `suspended` 액션은 admin.suspend_user 호출.

공개 인터페이스 (다른 피처가 호출 가능):
- `get_warned_count_for_user(session, target_user_id)` — 경고 누적 카운트 (자동 정지 정책 도입 시 admin이 호출)
"""

from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import ConflictError, NotFoundError, ValidationError
from app.features.admin import service as admin_service
from app.features.report.schemas import (
    ReportDetail,
    ReportListPage,
    ReportResolveRequest,
)
from app.shared.enums import ReportAction, ReportStatus
from app.shared.models import Message, Report

# ============================================================
# F-033 신고 생성
# ============================================================


async def create_report(
    session: AsyncSession,
    reporter_id: UUID,
    message_id: UUID,
    reason: str,
) -> ReportDetail:
    """신고 생성. 중복/자기 메시지/존재하지 않는 메시지 차단."""
    message = await session.scalar(select(Message).where(Message.id == message_id))
    if message is None:
        raise NotFoundError("메시지를 찾을 수 없습니다.")
    if message.sender_id == reporter_id:
        raise ValidationError("본인이 보낸 메시지는 신고할 수 없습니다.")

    # 사전 중복 검증 (UX 위해 명시 에러). UNIQUE 위반은 race fallback.
    existing = await session.scalar(
        select(Report).where(
            Report.message_id == message_id,
            Report.reporter_id == reporter_id,
        )
    )
    if existing is not None:
        raise ConflictError("이미 신고한 메시지입니다.")

    report = Report(reporter_id=reporter_id, message_id=message_id, reason=reason)
    session.add(report)
    try:
        await session.flush()
    except IntegrityError as e:
        # 동시성 race — UNIQUE 위반.
        raise ConflictError("이미 신고한 메시지입니다.") from e
    await session.refresh(report)
    return _to_detail(report)


# ============================================================
# F-037 관리자 — 큐 조회 + 처리
# ============================================================


async def list_pending_reports(
    session: AsyncSession,
    page: int,
    page_size: int,
) -> ReportListPage:
    """status='pending' 대기 큐. created_at ASC (오래된 것부터 처리)."""
    offset = (page - 1) * page_size
    rows = await session.scalars(
        select(Report)
        .where(Report.status == ReportStatus.PENDING)
        .order_by(Report.created_at.asc())
        .offset(offset)
        .limit(page_size + 1)  # has_more 판별
    )
    items_raw = list(rows.all())
    has_more = len(items_raw) > page_size
    items = [_to_detail(r) for r in items_raw[:page_size]]
    return ReportListPage(items=items, page=page, page_size=page_size, has_more=has_more)


async def resolve_report(
    session: AsyncSession,
    report_id: UUID,
    admin_user_id: UUID,
    request: ReportResolveRequest,
) -> ReportDetail:
    """report 처리. 이미 handled면 409. suspended 액션은 admin.suspend_user 호출."""
    report = await session.scalar(select(Report).where(Report.id == report_id))
    if report is None:
        raise NotFoundError("신고를 찾을 수 없습니다.")
    if report.status == ReportStatus.HANDLED:
        raise ConflictError("이미 처리된 신고입니다.")

    # side effect — suspended만 본 PR에서 처리. message_deleted는 chat_message 슬라이스 머지 후 후속.
    if request.resolution_action == ReportAction.SUSPENDED:
        message = await session.scalar(select(Message).where(Message.id == report.message_id))
        if message is None:
            raise NotFoundError("대상 메시지를 찾을 수 없습니다.")
        await admin_service.suspend_user(
            session,
            target_user_id=message.sender_id,
            admin_user_id=admin_user_id,
            suspend_reason=request.resolution_note or "신고 처리로 인한 정지",
        )

    report.status = ReportStatus.HANDLED
    report.resolution_action = request.resolution_action
    report.resolution_note = request.resolution_note
    report.handled_by = admin_user_id
    report.handled_at = datetime.now(UTC)
    await session.flush()
    await session.refresh(report)
    return _to_detail(report)


# ============================================================
# 공개 인터페이스
# ============================================================


async def get_warned_count_for_user(session: AsyncSession, target_user_id: UUID) -> int:
    """대상 사용자가 받은 'warned' 처리 카운트. 자동 정지 정책 도입 시 사용."""
    stmt = (
        select(func.count())
        .select_from(Report)
        .join(Message, Message.id == Report.message_id)
        .where(
            Report.resolution_action == ReportAction.WARNED,
            Message.sender_id == target_user_id,
        )
    )
    return await session.scalar(stmt) or 0


# ============================================================
# 내부 helper
# ============================================================


def _to_detail(row: Report) -> ReportDetail:
    return ReportDetail(
        id=row.id,
        reporter_id=row.reporter_id,
        message_id=row.message_id,
        reason=row.reason,
        status=row.status,
        resolution_action=row.resolution_action,
        resolution_note=row.resolution_note,
        handled_by=row.handled_by,
        handled_at=row.handled_at,
        created_at=row.created_at,
    )
