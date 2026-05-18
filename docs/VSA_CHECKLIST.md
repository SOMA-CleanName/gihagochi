# VSA 체크리스트

> [Vertical Slice Architecture](./VSA.md) 관점에서 **하네스가 갖춰졌는지 / 새 슬라이스를 어떻게 시작·머지하는지 / 12개 슬라이스가 어디까지 갔는지**를 점검하는 체크리스트.
> 전체 셋업 흐름은 [`../_workspace/SETUP_CHECKLIST.md`](../_workspace/SETUP_CHECKLIST.md). 본 문서는 그중 **VSA 관점에서 빠지면 안 되는 항목**만 추려서 항상 최신 상태로 유지.

---

## 1. 하네스 체크리스트 — 슬라이스를 꽂을 그릇이 있는가

슬라이스 작업을 시작하기 **전에** 갖춰져 있어야 할 인프라.
  
### 1.1 디렉토리 골격

**백엔드**
- [ ] `backend/app/__init__.py`
- [ ] `backend/app/core/` 폴더 생성
- [ ] `backend/app/shared/__init__.py` + `shared/models/`
- [ ] `backend/app/features/__init__.py`
- [ ] `backend/app/features/_template/` (복사 시작점)
- [ ] `backend/app/main.py` (자동 라우터 등록 포함)

**모바일**
- [ ] `mobile/lib/core/` 폴더 생성
- [ ] `mobile/lib/features/_template/`
- [ ] `mobile/lib/main.dart` (Sentry/Supabase/Firebase init + ProviderScope + go_router)

**관리자 웹**
- [ ] `admin/app/(admin)/layout.tsx`
- [ ] `admin/app/(admin)/_template/page.tsx`
- [ ] `admin/lib/supabase/{server,client,middleware}.ts`
- [ ] `admin/middleware.ts` (관리자 role 체크)

### 1.2 자동 등록 메커니즘

- [ ] **백엔드**: `main.py`가 `pkgutil.iter_modules(features.__path__)` 로 `router.py` 자동 import
- [ ] **백엔드**: `_` prefix 폴더(`_template/`)는 자동 등록에서 제외되는지 확인
- [ ] **모바일**: `core/router/app_router.dart`가 각 슬라이스 `routes.dart`의 `List<RouteBase>` 를 spread로 합치는 패턴 확립
- [ ] **모바일**: `_template/routes.dart`에 예시 라우트 1개 포함
- [ ] **관리자 웹**: App Router 파일 기반 라우팅으로 자동 (별도 설정 없음, 확인만)

### 1.3 `_template/` 가 작동하는가

새 슬라이스를 만들려면 `_template/`을 복사해서 시작해야 함. 템플릿이 살아있어야 함.

**백엔드 `_template/`**
- [ ] `SPEC.md` (양식 + 빈 섹션)
- [ ] `router.py` — 빈 `router = APIRouter(prefix="/_template")` + 예시 엔드포인트 1개
- [ ] `schemas.py` — Pydantic 예시 1개
- [ ] `service.py` — DB 세션 의존성 받는 예시 함수 1개
- [ ] `tests/test_router.py` — 스모크 테스트 1개

**모바일 `_template/`**
- [ ] `SPEC.md`
- [ ] `routes.dart` — `List<RouteBase> templateRoutes = [...]` export
- [ ] `presentation/template_screen.dart`
- [ ] `application/template_controller.dart` — `@riverpod` 예시
- [ ] `domain/template_model.dart` — freezed 예시
- [ ] `data/template_repository.dart`

**관리자 웹 `_template/`**
- [ ] `page.tsx` (Server Component)
- [ ] `_components/` 빈 폴더

### 1.4 슬라이스 외부 의존이 `core/`로 완비됐는가

새 슬라이스가 `core/`만 의존해서 시작 가능해야 함.

**백엔드 `core/`**
- [ ] `config.py` (Supabase URL/keys, FCM, Sentry, JWT)
- [ ] `db.py` (`get_session()` 의존성)
- [ ] `auth.py` (`get_current_user()`, `require_role()`)
- [ ] `supabase.py` (Storage / Auth admin)
- [ ] `fcm.py` (`send_push()`)
- [ ] `realtime.py` (`broadcast_to_idol_topic()`)
- [ ] `errors.py` (표준 에러 + Sentry 캡처)
- [ ] `logging.py`

**모바일 `core/`**
- [ ] `api/dio_client.dart` (JWT 첨부 + 401 refresh)
- [ ] `auth/auth_service.dart` + `auth_guard.dart`
- [ ] `realtime/realtime_service.dart`
- [ ] `push/push_service.dart`
- [ ] `storage/secure_storage.dart`
- [ ] `theme/` (ThemeData)
- [ ] `widgets/` (`AppButton`, `MessageBubble`, `LoadingView`, ...)
- [ ] `error/error_handler.dart`
- [ ] `router/app_router.dart`

### 1.5 격리 보장 장치

- [ ] `.github/CODEOWNERS`에 `core/`, `shared/`, `migrations/`, `docs/` 메인 빌더 지정 (✅ 완료)
- [ ] `.github/workflows/guard.yml` — 컨트리뷰터가 `core/` 만지면 자동 코멘트
- [ ] `.github/workflows/migrations.yml` — 마이그레이션 2개 이상이면 fail
- [ ] PR 템플릿에 "core/, shared/, 다른 features/ 수정 없음" 체크 (✅ 완료)

### 1.6 DB 기반

- [ ] `docs/SCHEMA.md` 테이블별 owner 명시 (✅ 완료, 검증 대기)
- [ ] `backend/migrations/versions/0001_initial.py` Supabase dev에 적용 + RLS 검증
- [ ] `0001_initial.py`이 만든 ENUM/테이블/RLS가 `SCHEMA.md`와 일치하는지 대조

---

## 2. 새 슬라이스 시작 체크리스트

피처 컨트리뷰터가 새 슬라이스를 시작할 때 (또는 메인 빌더가 레퍼런스 슬라이스 만들 때).

### 2.1 킥오프

- [ ] GitHub 이슈에 피처 ID + 슬라이스 폴더명 명시
- [ ] [`./FEATURES.md`](./FEATURES.md) §5 의존 그래프로 선행 슬라이스가 머지됐는지 확인
- [ ] 선행 슬라이스의 `SPEC.md` "공개 인터페이스" 읽기

### 2.2 폴더 복사

```bash
# 백엔드
cp -r backend/app/features/_template backend/app/features/<name>

# 모바일 (관리자 웹 피처 아니라면)
cp -r mobile/lib/features/_template mobile/lib/features/<name>
```

- [ ] 두 폴더 모두 복사됨 (관리자 전용 슬라이스 제외)
- [ ] `_template` 잔재 문자열 일괄 치환 (`templateRoutes` → `<name>Routes` 등)

### 2.3 SPEC.md 작성 (코드 작성 **전**)

- [ ] API 엔드포인트 목록 (METHOD + path + 설명)
- [ ] DB 읽기 / 쓰기 테이블 명시
- [ ] `core/` 의존 함수 시그니처 확인 (있는지 grep)
- [ ] 다른 슬라이스 의존 시 그 슬라이스 `SPEC.md`의 public 인터페이스에 있는지 확인
- [ ] 비즈니스 룰 / 엣지 케이스 작성
- [ ] **공개 인터페이스** 섹션 — 다른 슬라이스가 import할 수 있는 함수 명시 (없으면 "없음")

### 2.4 구현 순서

1. **DB 영향 검토** — 새 컬럼/테이블/RLS 필요하면 메인 빌더 핑 (`SCHEMA.md` 수정 / 새 마이그레이션)
2. **백엔드 라우터 + service** — SPEC.md의 API 시그니처 그대로
3. **백엔드 스모크 테스트** — 라우터가 200 / 401 / 403 분기 반환하는지
4. **앱 repository + controller** — 백엔드 라우터 호출
5. **앱 화면** — `presentation/`
6. **앱 routes.dart** — go_router 자동 수집에 등록
7. **수동 테스트** — `MANUAL_TEST.md` 작성하면서 dev 환경에서 실제 시나리오 돌리기

### 2.5 구현 중 발생할 수 있는 멈춤 신호 (사용자에게 보고)

- `core/`, `shared/`에 새 함수 필요
- DB 스키마 변경 필요
- 다른 슬라이스의 SPEC.md에 없는 함수 호출 필요
- 의존성 추가 필요 (`pyproject.toml` / `pubspec.yaml` / `package.json`)
- 환경 변수 신규 추가
- 마이그레이션 2개 이상 필요

---

## 3. 머지 전 셀프 체크리스트

PR 올리기 직전.

### 3.1 격리 검증

- [ ] `git diff --name-only main...HEAD` 결과가 다음만 포함:
  - `backend/app/features/<name>/`
  - `mobile/lib/features/<name>/`
  - (관리자 슬라이스라면) `admin/app/(admin)/<name>/`
  - (선택) `backend/migrations/versions/000X_*.py` 1개
- [ ] `core/`, `shared/`, 다른 `features/`, `docs/`, `.github/` 수정 0건
- [ ] 매니페스트 (`pyproject.toml`, `pubspec.yaml`, `package.json`) 수정 0건

### 3.2 슬라이스 내부 점검

- [ ] `SPEC.md` 모든 섹션 채움 (빈 섹션 X)
- [ ] SPEC.md의 API와 실제 라우터 시그니처 일치
- [ ] SPEC.md의 "공개 인터페이스" 함수가 실제로 `service.py`에 존재
- [ ] 다른 슬라이스에서 import한 함수가 그쪽 SPEC.md의 public 인터페이스에 있는지
- [ ] 테스트 1개 이상 (router 스모크 최소)

### 3.3 DB / 마이그레이션

- [ ] 마이그레이션 1개 이하
- [ ] 새 마이그레이션이 있다면 `SCHEMA.md` 동기 업데이트 필요 여부 메인 빌더 확인
- [ ] RLS 정책 영향 검토 (새 테이블/컬럼은 RLS 필수)

### 3.4 코드 스타일

- [ ] pre-commit이 통과 (ruff / dart format / prettier 자동 적용)
- [ ] 한국어 주석은 **의도/이유**만. WHAT은 X
- [ ] 함수 단일 책임 — 길어지면 분리

### 3.5 PR 본문

- [ ] 피처 ID + 변경 요약
- [ ] 수동 테스트 시나리오 (`MANUAL_TEST.md` 링크 또는 본문에 포함)
- [ ] 스크린샷 (앱 슬라이스의 경우)

위반 항목 있으면 **머지 전 수정**. 자체 판단 어렵다면 메인 빌더 확인.

---

## 4. 슬라이스 간 의존 추가 체크리스트

내 슬라이스가 다른 슬라이스의 함수를 호출하고 싶을 때.

- [ ] 대상 슬라이스 `SPEC.md`의 "공개 인터페이스" 섹션 확인 — 호출하려는 함수가 있는가?
- [ ] **있다면** → import + 사용. 내 `SPEC.md` "의존" 섹션에 추가:
  ```
  features.<other>.service.<func_name>
  ```
- [ ] **없다면** → 대상 슬라이스의 owner에게 핑. owner가 SPEC에 함수 추가 + 시그니처 안정화 후 별 PR로 머지. 그 다음 내 PR.
- [ ] 순환 의존 검사 — 대상 슬라이스가 내 슬라이스를 의존하면 의존 방향 재설계 또는 `core/`로 끌어올리기
- [ ] HTTP 호출 X — 같은 백엔드 프로세스 내 직접 함수 import (퍼포먼스 + 트랜잭션 일관성)

---

## 5. DB 스키마 변경 체크리스트

owner 슬라이스가 자기 테이블 스키마 변경 시.

- [ ] 변경 의도를 메인 빌더에게 보고 (CODEOWNERS 게이트)
- [ ] `docs/SCHEMA.md` 해당 테이블 섹션 업데이트 (메인 빌더가)
- [ ] Alembic 마이그레이션 1개 작성 (`alembic revision -m "<feature>: <change>"`)
- [ ] `op.upgrade()` + `op.downgrade()` 양방향 작성
- [ ] RLS 정책 영향 검토:
  - 새 컬럼: 기존 RLS로 충분한가
  - 새 테이블: 새 RLS 정책 필수
- [ ] dev Supabase에 적용 후 검증
- [ ] 동시 진행 PR이 같은 테이블 만지는지 확인 — 늦은 PR이 `alembic merge`

---

## 6. 12개 슬라이스 진행 트래커

각 슬라이스의 현재 단계. 머지 시 업데이트.

상태: `⬜ 미착수` / `🟨 SPEC` / `🟧 구현 중` / `🟩 머지`

| # | 슬라이스 | 백엔드 | 모바일 | 관리자 | 비고 |
|---|---|---|---|---|---|
| 1 | `auth` | ⬜ | ⬜ | ⬜ | **레퍼런스 슬라이스 (Phase 6)**. 하네스 완성 후 첫 작업 |
| 2 | `idol_discovery` | ⬜ | ⬜ | — | `auth` + `admin(F-035)` 선행 |
| 3 | `subscription` | ⬜ | ⬜ | — | `idol_discovery` 선행 |
| 4 | `chat_room` | ⬜ | ⬜ | — | `subscription` 선행 |
| 5 | `chat_message` | ⬜ | ⬜ | — | `chat_room` + Realtime 검증 선행 |
| 6 | `chat_media` | ⬜ | ⬜ | — | `chat_message` + Storage 선행 |
| 7 | `chat_meta` | ⬜ | ⬜ | — | `chat_message` 선행 |
| 8 | `notification` | ⬜ | ⬜ | — | FCM 셋업 선행 |
| 9 | `profile` | ⬜ | ⬜ | — | `auth` 선행 |
| 10 | `report` | ⬜ | ⬜ | ⬜ | `chat_message` + 관리자 슬라이스 선행 |
| 11 | `admin` | ⬜ | — | ⬜ | `auth(F-036)` + 관리자 웹 하네스 선행 |
| 12 | `gift` | — | ⬜ | — | UI만 (1차). `chat_room` 선행 |

**현재 단계 요약 (2026-05-16 기준)**: 12 슬라이스 전부 `⬜ 미착수`. 하네스 0%. 가장 먼저 §1 하네스 체크리스트를 완료해야 슬라이스 작업 시작 가능.

---

## 7. 관련 문서

- [`./VSA.md`](./VSA.md) — VSA 설계 정리 (왜 / 무엇이 / 어디까지)
- [`../AGENTS.md`](../AGENTS.md) — AI 에이전트 작업 룰
- [`./CONTRIBUTING.md`](./CONTRIBUTING.md) — 사람용 라이프사이클
- [`./FEATURES.md`](./FEATURES.md) — 피처 / 슬라이스 매핑 / 의존 그래프
- [`./SCHEMA.md`](./SCHEMA.md) — DB 스키마 + 테이블 owner
- [`../_workspace/SETUP_CHECKLIST.md`](../_workspace/SETUP_CHECKLIST.md) — 메인 빌더 전체 Phase 0~6 체크리스트 (VSA 외 항목 포함)
