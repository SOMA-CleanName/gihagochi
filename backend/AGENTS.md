# backend/AGENTS.md — 백엔드 stack 룰

루트 [`AGENTS.md`](../AGENTS.md)의 절대 룰은 그대로. 이 파일은 **백엔드 stack-specific**.

---

## Stack

- **Python 3.12+** (운영은 3.13. 로컬 3.14도 호환)
- **FastAPI** (`fastapi[standard]`) + **uvicorn**
- **SQLAlchemy 2 async** (`Mapped[T]`, `mapped_column`) + **asyncpg**
- **Alembic** (마이그레이션은 sync psycopg — asyncpg는 multi-statement 비호환)
- **Pydantic v2** + **pydantic-settings**
- **structlog** (구조화 로그) + **Sentry**
- **slowapi** (rate limit)
- **PyJWT** (Supabase JWT 검증)

## Run

```bash
cd backend
.venv/Scripts/python -m uvicorn app.main:app --reload    # 개발
.venv/Scripts/python -m pytest                            # 테스트
.venv/Scripts/python -m ruff check --fix .                # lint
alembic upgrade head                                       # 마이그레이션 적용
alembic revision -m "add foo"                              # 새 마이그레이션
```

---

## 폴더 구조

```
backend/
├── app/
│   ├── main.py              # 자동 등록. 수정 금지.
│   ├── core/                # 인프라. 수정 시 메인 빌더 합의.
│   ├── shared/              # 모델/공유 스키마. 수정 시 메인 빌더 합의.
│   └── features/
│       ├── _template/       # 복사용 (auto-register 스킵)
│       └── <피처>/          # ★ 작업 영역
├── migrations/              # Alembic. 수정 시 메인 빌더 합의.
├── tests/                   # E2E
├── conftest.py              # 공용 픽스처
└── pyproject.toml           # 의존성. 수정 시 메인 빌더 합의.
```

---

## 새 피처 시작

```bash
cp -r app/features/_template app/features/<폴더>
# 폴더명은 _ 없이. 자동 라우터 등록됨.
```

순서: **SPEC.md → schemas.py → service.py → router.py → tests/**

---

## 라우터 패턴

라우터는 **얇게**. 파라미터 추출 + service 호출만. 비즈 로직은 service.

```python
from typing import Annotated
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import AuthedUser, FanUser, IdolUser, AdminUser
from app.core.db import get_session
from app.features.<폴더> import service
from app.features.<폴더>.schemas import FooResponse

router = APIRouter(prefix="/foo", tags=["foo"])


@router.get("/{id}", response_model=FooResponse)
async def get_foo(
    id: UUID,
    user: AuthedUser,                                     # 인증만
    session: Annotated[AsyncSession, Depends(get_session)],
) -> FooResponse:
    return await service.get_foo(session, id, user)
```

권한별 미리 정의된 Annotated 타입 (`core/auth.py`):
- `AuthedUser` — 인증만
- `FanUser` — role=fan
- `IdolUser` — role=idol (F-025, F-026 등)
- `AdminUser` — role=admin (F-035, F-037, F-038)
- 복합: `Annotated[CurrentUser, Depends(require_role(UserRole.IDOL, UserRole.ADMIN))]`

---

## Service 패턴

DB 접근 + 비즈 로직. 라우터에서 호출. 다른 피처가 호출 가능한 함수는 `SPEC.md`의 "공개 인터페이스"에 명시.

```python
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError, ForbiddenError
from app.shared.models import Profile, Message
from app.shared.enums import MessageType


async def get_foo(session: AsyncSession, id: UUID, user: CurrentUser) -> FooResponse:
    profile = await session.scalar(select(Profile).where(Profile.id == id))
    if profile is None:
        raise NotFoundError("프로필이 없습니다.")
    return FooResponse.model_validate(profile, from_attributes=True)
```

- 단순 조회: `session.scalar(select(...))` → 1개 or None
- 다수 조회: `(await session.scalars(select(...))).all()`
- INSERT: `session.add(obj)` — commit은 `get_session` 의존성이 자동 처리
- 트랜잭션 명시: `async with session.begin(): ...`

---

## Schemas (Pydantic)

```python
from pydantic import BaseModel, Field
from datetime import datetime
from uuid import UUID

class FooRequest(BaseModel):
    content: str = Field(min_length=1, max_length=1000)

class FooResponse(BaseModel):
    id: UUID
    content: str
    created_at: datetime
```

- 입출력 분리 (Request / Response). ORM 모델 직접 노출 X.
- `model_validate(orm_obj, from_attributes=True)` 또는 명시적 매핑.

---

## 에러 처리

```python
from app.core.errors import NotFoundError, ForbiddenError, ConflictError, ValidationError

raise NotFoundError("...")     # → 404 {error:{code:"not_found",...}}
raise ForbiddenError("...")    # → 403
raise ConflictError("...")     # → 409
raise ValidationError("...")   # → 422
```

표준 응답 + 5xx 자동 Sentry 캡처는 `core/errors.register_error_handlers`가 처리. 직접 try/except로 잡지 말 것.

---

## DB 모델 (shared/models)

**수정 금지** (메인 빌더 합의). 사용만:

```python
from app.shared.models import Profile, IdolProfile, Subscription, Message, ...
from app.shared.enums import UserRole, UserStatus, MessageType, MediaType, ...
```

- 모든 모델은 `Base` (from `app.core.db`) 상속
- 타임스탬프: `DateTime(timezone=True)`
- ENUM: `SAEnum(EnumClass, name="pg_name", create_type=False)` — 마이그레이션이 이미 만든 타입
- 컬럼 추가/변경 필요 → 메인 빌더에게 핑 (마이그레이션 동반)

---

## ★ Supabase / RLS — 중요

백엔드는 **service_role**로 DB 연결 (RLS 우회). 즉:

- **권한 검증은 우리 코드 책임** — `require_role(...)` + service 레이어의 비즈 룰
- **RLS 정책은 클라이언트 직결용**(모바일 앱이 Supabase 직접 호출) — 백엔드 SQLAlchemy 쿼리는 RLS 안 거침
- 그래서 service에서 항상 "이 user가 이 리소스 볼/쓸 권한 있나?" 명시적 검증

Supabase 클라이언트 (Auth/Storage/Realtime용):

```python
from app.core.supabase import get_supabase, get_supabase_admin

client = await get_supabase()        # anon. RLS 적용. 사용자 토큰 위임 시.
admin = await get_supabase_admin()   # service_role. RLS 우회. ★결과 사용자에 노출 금지.
```

---

## 인증

```python
# 인증된 사용자 정보 사용
async def handler(user: AuthedUser):
    user.id           # UUID
    user.role         # UserRole
    user.status       # UserStatus (active 보장 — suspended는 403으로 사전 차단)
    user.display_name # str
```

JWT 검증은 `core/auth.get_current_user`가 자동:
- Authorization 헤더 추출 (Bearer)
- HS256 + audience="authenticated"로 verify
- `profiles` 조회 → suspended/deleted 차단

---

## 마이그레이션

```bash
alembic revision -m "add notification_throttle"   # 새 파일 생성
# versions/000X_add_notification_throttle.py 수동 작성
alembic upgrade head                               # 적용
alembic downgrade -1                               # 1단계 롤백
```

룰:
- **PR당 1개 이하** (2개 이상이면 CI fail)
- **raw SQL 사용** (env.py의 `target_metadata = None` — autogenerate 안 함)
- `alembic.ini`는 **ASCII only** (cp949 인코딩 회피)
- DATABASE_URL은 env.py가 자동으로 psycopg로 변환

---

## 테스트

```python
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

# 공용 픽스처 (conftest.py):
# - client: ASGI 직결 httpx
# - session: AsyncSession + 자동 rollback
# - make_auth_headers: 가짜 JWT 헬퍼

@pytest.mark.asyncio
async def test_endpoint_authed(client: AsyncClient, make_auth_headers):
    headers = make_auth_headers(role="fan")
    r = await client.get("/foo/123", headers=headers)
    assert r.status_code == 200

@pytest.mark.asyncio
async def test_service_unit(session: AsyncSession):
    from app.features.<폴더>.service import get_foo
    # session 픽스처는 dev DB에 연결. 끝에 rollback으로 격리.
```

피처별 `tests/` 폴더에 최소 1개 (router 스모크). 비즈 룰 분기마다 1개씩.

---

## 흔한 함정

- **`_template` 폴더는 자동 등록 X** — `_` 시작 폴더는 main.py가 스킵
- **마이그레이션 2개 이상** → CI fail. 한 PR에 1개로 합쳐서 작성
- **`alembic.ini`에 한글/특수문자** → cp949 디코드 실패 (Windows). ASCII only
- **`asyncpg`로 마이그레이션** → multi-statement 비호환. migrations/env.py가 psycopg로 자동 전환
- **service_role 결과 그대로 응답에 노출** → RLS 우회 결과 유출. 항상 권한 검증 후 필요한 필드만 매핑
- **`from supabase import Client`** (sync) — 우리는 async. `AsyncClient` + `create_async_client` 사용
- **JWT audience 검증** — Supabase 기본은 `"authenticated"`. 다른 값이면 decode 실패
- **CHECK 제약 위반** → DB에서 IntegrityError. service 레벨에서 미리 검증 권장 (예: messages.type별 필수 필드)

---

## 의존성 추가 필요 시

`pyproject.toml`은 메인 빌더 영역. 새 라이브러리 필요하면 **메인 빌더에게 핑** (사용 이유 + 대안 검토 포함).

자주 필요한 게 이미 박혀있음: requests/httpx/dio (외부 호출), structlog (로그), pydantic (검증), sqlalchemy/asyncpg (DB). 그 외에는 정말 필요한지 한 번 더 생각.
