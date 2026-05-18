# ARCHITECTURE.md — gihagochi 시스템 구조 + 핵심 결정

이 문서는 **왜 이렇게 설계했는가**를 기록한다.
**무엇을 했는가**는 코드와 [`FEATURES.md`](./FEATURES.md), [`SCHEMA.md`](./SCHEMA.md)에 있다.

---

## 1. 시스템 개요

```
┌────────────────────────┐      ┌─────────────────────┐
│ mobile (Flutter)       │      │ admin (Next.js 16)  │
│  - 팬 + 아이돌 공용    │      │  - 관리자 전용      │
└─────┬──────────────────┘      └──────┬──────────────┘
      │ Supabase 직결 (RLS)            │ Supabase 직결 (RLS, server)
      │ + 백엔드 API (비즈 로직)       │ + 백엔드 API (관리 액션)
      ▼                                ▼
   ┌──────────────────────────────────────┐
   │ backend (FastAPI / Python 3.13+)     │
   │  - 비즈니스 룰 + fan-out 트리거      │
   │  - service_role 로 DB 접근 (RLS 우회)│
   └─────┬────────────────────────────────┘
         │ asyncpg (런타임) / psycopg (마이그레이션)
         ▼
   ┌──────────────────────────────────────┐
   │ Supabase Postgres                    │
   │  - 10 tables + RLS + broadcast 트리거│
   │  - Realtime (idol:<id> 토픽)         │
   │  - Auth (JWT HS256)                  │
   │  - Storage (이미지/음성)             │
   └──────────────────────────────────────┘
```

3개 클라이언트가 같은 Supabase에 붙고, 비즈 로직과 fan-out은 백엔드가 처리.

---

## 2. 핵심 결정 (왜)

### 2.1 왜 Supabase

**대안**: 자체 Postgres + Redis(realtime) + S3(storage) + 자체 auth.
**선택 이유**:
- Auth + Realtime + Storage + RLS가 한 통에 있어서 인프라 운영 비용 0
- Postgres 그대로라 마이그레이션 자유
- 무료 플랜에서 MVP 검증 가능
- 사이드 효과: RLS를 잘 짜야 모바일 직결 안전 — 보안 정책이 강제됨

**대가**: vendor lock-in 어느 정도. 다만 핵심은 표준 Postgres라 이전 가능.

### 2.2 왜 vertical slice architecture

**대안**: layered (controllers/services/models 분리), DDD 도메인 경계.
**선택 이유**:
- 팀원 5명이 38개 피처를 병렬로 짠다 → **머지 충돌이 가장 큰 비용**
- vertical slice는 한 PR이 한 폴더 안에서 닫힘 → 충돌 0에 가까움
- AI 코딩 에이전트(Claude/Codex)와 궁합 좋음 — 컨텍스트가 한 폴더에 모임
- 단점인 중복은 `core/`, `shared/` 공통 인프라로 흡수

룰은 [`AGENTS.md`](../AGENTS.md)의 절대 룰 1~5번에 강제.

### 2.3 왜 backend는 service_role (RLS 우회)

**Supabase 클라이언트 직결 = RLS 강제됨.** 백엔드는 service_role key로 우회한다.

이유:
- 백엔드 비즈니스 룰(예: "신고 누적 3건 → 자동 정지")이 여러 테이블 join + 권한 변경 필요 → RLS 정책으로 표현 어려움
- 백엔드는 이미 JWT 검증 + `require_role()`로 인증/인가 처리. 이중 방어 불필요
- 마이그레이션, 백오피스 액션은 RLS 없는 게 단순

**대가**: 백엔드 코드가 권한 체크를 빠뜨리면 무방비. 그래서 라우터에 `AuthedUser` / `AdminUser` 타입 의무화 (`backend/AGENTS.md` 참고).

### 2.4 Realtime fan-out 전략 — `idol:<id>` 토픽

1:N 브로드캐스트(아이돌 1명 → 팬 수천 명). 각 팬마다 INSERT row 만들면 DB 폭증.

**선택**: 메시지는 `messages` 테이블에 1 row만. 모바일은 `idol:<idol_id>` 토픽 구독. DB 트리거가 INSERT 시 Realtime 채널로 broadcast.

- 팬 측 읽음 처리는 `message_reads` (per-user row) — 카운팅 필요할 때만 INSERT
- 모바일에서 `realtime_service.dart`가 토픽 구독 캐싱 (중복 채널 방지)
- 백엔드는 `core.realtime.broadcast_to_idol_topic()` 헬퍼로 발행 (트리거가 처리 못하는 시스템 메시지용)

### 2.5 왜 Riverpod (Flutter)

**대안**: Bloc, GetX, Provider, FlutterFlow.
- **Riverpod**: codegen + 컴파일 타임 안전 + DI 통합 + AsyncValue로 loading/error 자동 매핑
- **Bloc**: 보일러플레이트 많고 vertical slice와 궁합 약함 (이벤트 정의가 무거움)
- **FlutterFlow**: 1:N 브로드캐스트 + 음성/녹음 + 푸시 같은 복합 기능 한계

Riverpod 3.x 사용. **`mobile/AGENTS.md`의 analyzer 8.4 lock 주의 참고** — Flutter SDK 제약으로 codegen 패키지들이 일부 버전에 lock됨.

### 2.6 왜 Next.js 16 + Server Components

**관리자 웹은 트래픽 적고 SEO 무관**. SPA 대신 SSR/RSC가 유리:
- Supabase 호출이 서버에서 끝남 → 클라이언트 번들 작고 빠름
- 인증 가드는 `proxy.ts` (Next 16에서 middleware 이름 변경) 한 곳에서
- 폼/뮤테이션만 `'use client'`

**Next 16 breaking change 다수 — `admin/AGENTS.md` 참고.**

### 2.7 왜 monorepo

**대안**: 3개 레포 (mobile/backend/admin).
- 단일 PR로 BE+FE 동시 변경 가능 (API 스키마 변경 시 결정적)
- 공통 문서(`docs/`, `AGENTS.md`)가 한 곳
- CI에서 변경 영역만 빌드(`paths-filter`) 가능

**대가**: 깃 로그 시끄러움, 배포 파이프라인 분기 필요 — 둘 다 감당 가능.

---

## 3. 인증 / 권한 흐름

```
┌──────────────────┐
│ 클라이언트       │
│ (mobile / admin) │
└────┬─────────────┘
     │ Supabase Auth (password / OAuth)
     ▼
┌──────────────────┐
│ Supabase Auth    │  JWT 발급 (HS256, audience="authenticated")
│  + auth.users    │  user_metadata.role: fan | idol | admin
└────┬─────────────┘
     │
     ├──→ Supabase 직결 (모바일/admin)
     │    → RLS 정책이 user_id로 행 단위 가드
     │
     └──→ 백엔드 API
          → Authorization: Bearer <JWT>
          → backend/app/core/auth.py가 검증
          → AuthedUser / AdminUser / IdolUser / FanUser Annotated 의존성으로 강제
          → service_role로 DB 접근 (RLS 우회) → 비즈 룰 적용
```

핵심:
- **클라이언트가 직접 DB 접근 = RLS가 유일한 방어선** → RLS 정책 작성 필수
- **백엔드 경유 = 라우터에서 role 타입 의존성으로 1차 차단** + 함수 내부에서 비즈 룰 추가 검증
- profiles 테이블의 role 컬럼은 JWT user_metadata와 sync. JWT가 권위.

---

## 4. 마이그레이션 정책

**1 PR = 1 마이그레이션 (최대).** [`AGENTS.md`](../AGENTS.md) 절대 룰 3번.

이유:
- 머지 순서가 곧 마이그레이션 순서. PR 두 개가 같은 테이블 건드리면 충돌
- 1개로 제한 = 컨트리뷰터가 스키마 변경 = 메인 빌더와 미리 합의 강제
- Alembic 의존성 그래프 단순 유지

도구:
- 작성: `alembic revision --autogenerate -m "..."` (psycopg sync)
- 적용: `alembic upgrade head`
- 런타임: 백엔드는 asyncpg로 같은 DATABASE_URL 사용 (core/config.py가 드라이버 자동 변환)

스키마 변경 자체는 [`SCHEMA.md`](./SCHEMA.md) 수정 + 사용자(메인 빌더) 승인 필수.

---

## 5. 폴더 책임 매트릭스

| 경로 | 책임 | 누가 수정 |
|---|---|---|
| `backend/app/core/`, `shared/`, `migrations/` | 인프라 + 공통 모델 + 스키마 | 메인 빌더만 |
| `backend/app/features/<폴더>/` | 백엔드 피처 1개 | 피처 컨트리뷰터 |
| `mobile/lib/core/` | 모바일 인프라 (config/auth/dio/realtime/push/theme/widgets) | 메인 빌더만 |
| `mobile/lib/features/<폴더>/` | 모바일 피처 1개 (domain/data/application/presentation) | 피처 컨트리뷰터 |
| `admin/lib/`, `admin/proxy.ts`, `admin/app/layout.tsx` | 관리자 인프라 + 루트 레이아웃 | 메인 빌더만 |
| `admin/app/(admin)/<폴더>/` | 관리자 페이지 1개 | 피처 컨트리뷰터 |
| `docs/`, `.github/` | 룰/명세/CI | 메인 빌더만 |

CI(`.github/workflows/guard.yml`)가 외부 영역 변경 시 코멘트로 경고.

---

## 6. 캐시 / 에러 전략

### 6.1 모바일
- **Riverpod provider 캐시**: in-memory, 자동 dispose. `keepAlive: true`는 auth/supabase/dio 같은 인프라만
- **Supabase Realtime**: 채널 구독 캐싱 (`realtime_service.dart`) — 같은 토픽 중복 구독 방지
- **이미지**: `cached_network_image` 디스크 캐시
- **에러 분류**: `AppError` 계층 (`Network`, `Unauthorized`, `Server`, `Unknown`) + `ErrorHandler.handle()` → Sentry는 5xx/Unknown만 보냄 (사용자 입력 에러는 노이즈)

### 6.2 관리자 웹
- **TanStack Query**: stale 1분, refetchOnWindowFocus off (관리자 화면 자주 새로고침 불필요)
- **Next.js RSC**: 페이지 데이터는 매 요청 fresh (관리 데이터의 stale 비용 큼). `cacheLife`/`cacheTag` 미사용 default
- **뮤테이션 후**: `router.refresh()` (RSC 재요청) 또는 `revalidateTag('xxx', 'max')`

### 6.3 백엔드
- **DB 세션**: 요청당 1개 (`get_session` dependency). 자동 commit / 예외 시 rollback
- **Rate limit**: slowapi, `/login`/`/signup` 등 인증 엔드포인트는 별도 강한 제한
- **로깅**: structlog JSON, request_id 컨텍스트 자동 부착
- **Sentry**: 5xx만 캡처. 4xx는 비즈 에러로 처리

---

## 7. 배포

| 영역 | 호스팅 | 빌드 |
|---|---|---|
| backend | Railway (Docker 멀티스테이지) | `docker build` → 자동 push 시 redeploy |
| admin | Vercel (Next 16 native) | GitHub push → 자동 |
| mobile | 사이드로드 (베타) / 추후 스토어 | flutter build apk / ipa (수동, CI는 analyze만) |
| DB | Supabase managed | 마이그레이션은 GitHub Actions에서 `alembic upgrade head` 수동 트리거 |

환경 분리: `dev` Supabase 프로젝트 + `prod` 별도. 시크릿은 GitHub Secrets / Vercel env / Railway env.

---

## 8. 미해결 / 추후 결정

- **Supabase Edge Functions vs 백엔드**: 가벼운 webhook은 Edge Functions가 효율적. 일단 모두 백엔드로 통일 (운영 복잡도 낮춤)
- **iOS APNs 직접 vs FCM iOS bridge**: 일단 FCM 통합 (Android+iOS 한 코드). 푸시 신뢰성 이슈 보고되면 APNs 직접 검토
- **Realtime 채널 폭증 대비**: idol:<id> 토픽 수가 아이돌 수에 비례. Supabase Realtime은 10k 동시 채널까지 무료 — 초과 시 유료 플랜 또는 자체 ws 검토

---

## 더 자세히

- [`AGENTS.md`](../AGENTS.md) — 작업 룰 본체
- [`backend/AGENTS.md`](../backend/AGENTS.md) / [`mobile/AGENTS.md`](../mobile/AGENTS.md) / [`admin/AGENTS.md`](../admin/AGENTS.md) — stack-specific
- [`FEATURES.md`](./FEATURES.md) — 38개 피처 → 12개 작업 단위
- [`SCHEMA.md`](./SCHEMA.md) — DB 스키마 + RLS
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) — 컨트리뷰터 라이프사이클
