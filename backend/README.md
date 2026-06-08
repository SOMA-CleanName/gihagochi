# backend/ — 앙코르 (encore) 백엔드

FastAPI + SQLAlchemy 2 async + Alembic + Supabase.
**Phase 2 완료 상태** — 하네스 (`core/`, `shared/`, `_template/`, `main.py`) + 테스트 + Docker/Railway 설정 배치됨.
피처 구현은 Phase 6부터 `app/features/<폴더>/`.

AI 에이전트 룰: [`AGENTS.md`](./AGENTS.md). 사람 가이드: [`../docs/CONTRIBUTING.md`](../docs/CONTRIBUTING.md).

---

## 폴더 구조

```
backend/
├── app/
│   ├── main.py              # FastAPI 부트스트랩 + 자동 라우터 등록
│   ├── core/                # 인프라 (config, db, auth, supabase, fcm, realtime, errors, logging, ratelimit)
│   ├── shared/
│   │   ├── enums.py         # 9 Postgres ENUM과 1:1 매칭
│   │   └── models/          # SQLAlchemy 모델 (테이블당 1파일)
│   └── features/
│       ├── _template/       # 새 피처 복사 베이스 (auto-register 스킵)
│       └── <피처>/          # Phase 6+
├── migrations/              # Alembic (sync psycopg)
│   └── versions/0001_initial.py
├── tests/                   # E2E / 통합
├── conftest.py              # 공용 픽스처 (client / session / make_auth_headers)
├── pyproject.toml           # 의존성 + ruff/pytest 설정
├── Dockerfile               # 멀티스테이지 (builder + runtime)
├── .dockerignore
├── railway.toml             # Railway 배포 설정
├── alembic.ini              # ASCII only (cp949 회피)
└── .env.example
```

> 드라이버: **마이그레이션 = sync psycopg v3**, **런타임 = async asyncpg**.
> 이유: asyncpg는 prepared statement당 1 command만 허용 → 초기 multi-statement DDL과 충돌.

---

## 셋업

### 1. Python 환경 (3.12+ 필수, 3.13 권장)

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -e ".[dev]"
```

또는 bash:

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
```

### 2. 환경변수

`.env.example` → `.env` 복사 후 채움:

```powershell
Copy-Item .env.example .env
notepad .env
```

필수 값:
- `DATABASE_URL` — Supabase Session Pooler URL (마이그레이션 + 런타임 공용)
- `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` — Studio → Settings → API
- `SUPABASE_JWT_SECRET` — Studio → Settings → API → JWT Secret

선택:
- `SENTRY_DSN`
- FCM (둘 중 하나):
  - `FCM_SERVICE_ACCOUNT_JSON` — JSON 통째 (Railway/Vercel 등 cloud 권장)
  - `FCM_SERVICE_ACCOUNT_PATH` — 파일 경로 (로컬 개발용)
  - 자세히는 `.env.example` 의 FCM 섹션

### 3. 마이그레이션 적용

```bash
alembic upgrade head
```

성공 시:
```
INFO  [alembic.runtime.migration] Running upgrade  -> 0001_initial, initial schema ...
```

### 4. 앱 실행

```bash
uvicorn app.main:app --reload
# → http://localhost:8000/health → {"status":"ok"}
# → http://localhost:8000/docs   → OpenAPI UI
```

### 5. 테스트

```bash
pytest                                          # 전체
pytest tests/integration/test_health.py -v      # 스모크만
pytest app/features/<폴더>/tests/               # 특정 피처
```

`conftest.py` 픽스처:
- `client` — ASGI 직결 httpx (네트워크 X)
- `session` — AsyncSession + 자동 rollback (dev DB 사용, 테스트 간 격리)
- `make_auth_headers` — 가짜 JWT 헬퍼

---

## 마이그레이션 가이드

### 적용

```bash
alembic upgrade head        # 최신까지
alembic downgrade -1        # 1단계 롤백
alembic downgrade base      # 전부 롤백 (개발용)
alembic current             # 현재 리비전 확인
alembic history             # 이력
```

### 새 마이그레이션 작성

```bash
alembic revision -m "add notification_throttle"
# → versions/000X_add_notification_throttle.py 생성됨
# 수동으로 upgrade() / downgrade() 작성 (raw SQL 권장)
```

룰:
- **PR당 1개 이하** (CI 가드)
- **raw SQL** 사용 (env.py의 `target_metadata = None` — autogenerate 미사용)
- `alembic.ini`는 **ASCII only**

### 검증 (Studio SQL Editor)

```sql
-- 10개 테이블 + RLS 활성화
SELECT tablename, rowsecurity FROM pg_tables
WHERE schemaname = 'public' ORDER BY tablename;

-- 9개 ENUM
SELECT typname FROM pg_type WHERE typtype = 'e' ORDER BY typname;

-- 헬퍼 함수 3개
SELECT proname FROM pg_proc
WHERE pronamespace = 'public'::regnamespace
  AND proname IN ('is_admin', 'is_active_idol', 'is_subscribed_to');

-- 정책 카운트
SELECT tablename, COUNT(*) FROM pg_policies
WHERE schemaname = 'public' GROUP BY tablename ORDER BY tablename;

-- broadcast 트리거
SELECT tgname FROM pg_trigger WHERE tgname = 'tg_messages_broadcast';
```

---

## 배포 (Railway)

[`railway.toml`](./railway.toml) + [`Dockerfile`](./Dockerfile) 사용.

### 사전

1. Railway 대시보드 → New Project → Deploy from GitHub
2. Root directory를 `backend/`로 설정
3. Variables에 환경변수 등록 (위 §셋업 §2 동일)

### 로컬 빌드 검증

```bash
docker build -t gihagochi-backend:test .
docker run --rm -p 8000:8000 --env-file .env gihagochi-backend:test
curl http://localhost:8000/health
```

### 배포 후 검증

- `/health` 200 OK
- Sentry: 의도적 에러로 캡처 확인 (임시 라우터 `raise Exception("test")` 추가 → 호출 → 대시보드 확인 → 제거)

### 마이그레이션 적용

Dockerfile에 포함 안 됨. 두 가지 방법:
- **로컬에서**: `alembic upgrade head` (DATABASE_URL이 prod 가리킬 때 주의)
- **Railway pre-deploy command**: Settings → Deploy → Pre-deploy command에 `alembic upgrade head` 추가

---

## 흔한 이슈

| 증상 | 원인 / 해결 |
|---|---|
| `UnicodeDecodeError: 'cp949' codec can't decode byte ...` (alembic.ini) | 한국어 Windows의 locale 인코딩이 cp949. alembic은 ini를 locale로 읽음. **`alembic.ini`는 ASCII only** (한글/em-dash 금지). |
| `socket.gaierror: [Errno 11001] getaddrinfo failed` | Direct connection(`db.X.supabase.co`)은 무료 플랜에서 IPv6 only. **Session Pooler URL** 사용 (`aws-X-region.pooler.supabase.com:5432`). |
| `asyncpg.exceptions.PostgresSyntaxError: cannot insert multiple commands into a prepared statement` | asyncpg는 prepared statement당 1 command만 허용. **마이그레이션은 sync psycopg** (env.py가 자동 변환). |
| `realtime.broadcast_changes does not exist` | Supabase Realtime extension 미활성. Studio → Database → Extensions에서 `realtime` 활성. 또는 `0001_initial.py` §23 broadcast 트리거만 임시 주석 후 재적용. |
| `permission denied for schema auth` | service_role 또는 postgres 역할로 접속 필요. anon 키로는 안 됨. |
| `pydantic ValidationError: 4 validation errors for Settings` | `.env`에 `SUPABASE_*` 키 누락. Studio → Settings → API에서 복사. |
| `error: Microsoft Visual C++ 14.0 or greater is required` (pyiceberg) | `supabase>=2.16`이 `storage3`를 통해 `pyiceberg`(C 확장) 끌어옴. Python 3.14 wheel 없어 빌드 실패. → pyproject가 `supabase<2.16` cap으로 회피. |
| `cannot drop type ... because ...` (downgrade) | 의존 객체 있음. `CASCADE` 추가 또는 역순으로 drop. |

---

## 다음 단계 (Phase 6+)

새 피처 작업은 `_template` 복사로 시작:

```bash
cp -r app/features/_template app/features/<폴더>
# 그 다음: SPEC.md → schemas.py → service.py → router.py → tests/
```

상세 패턴: [`AGENTS.md`](./AGENTS.md) (AI/사람 공용 — 짧고 강한 룰).
라이프사이클 가이드: [`../docs/CONTRIBUTING.md`](../docs/CONTRIBUTING.md).
