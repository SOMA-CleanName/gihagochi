"""F-XXX 기능명 — 서비스 레이어.

라우터는 얇게(파라미터 추출 + service 호출). 비즈니스 로직 / DB 접근은 모두 여기.

공개 인터페이스 (다른 피처가 호출 가능):
- `get_example(session, user_id)` — 예시
"""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError
from app.features._template.schemas import ExampleResponse
from app.shared.models import Profile


async def get_example(session: AsyncSession, user_id: UUID) -> ExampleResponse:
    """예시 — 사용자 프로필 조회 후 응답 스키마로 매핑."""
    profile = await session.scalar(select(Profile).where(Profile.id == user_id))
    if profile is None:
        raise NotFoundError("프로필을 찾을 수 없습니다.")
    return ExampleResponse(
        user_id=profile.id,
        display_name=profile.display_name,
    )
