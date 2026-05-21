# gihagochi

> 관리자 승인을 거친 아이돌이 자기 채팅방에서 **메시지 1개를 N명의 응원 팬에게 fan-out** 하고,
> 팬은 1:1처럼 보이는 화면에서 아이돌에게 개인 메시지를 보낼 수 있는 모바일 앱.

핵심 컨셉: 아이돌 메시지 1개 = 모든 응원 팬에게 동일 도달 / 팬 메시지 1개 = 해당 아이돌만 수신.
팬 UX는 1:1 대화처럼 보이지만 실제 구조는 1:N.

---

## 모노레포 구조

```
gihagochi/
├── backend/        # FastAPI (Python)
├── mobile/         # Flutter (iOS + Android)
├── admin/          # Next.js (관리자 웹)
├── docs/           # 아키텍처 / 스키마 / 컨트리뷰팅 가이드
└── .github/        # CI 워크플로우, PR/이슈 템플릿
```

각 폴더는 독립 프로젝트처럼 동작하지만, DB 스키마와 인증 토큰을 공유.

---

## 기술 스택

| 영역 | 스택 |
|---|---|
| 백엔드 | FastAPI, SQLAlchemy 2 (async), Alembic, asyncpg |
| 모바일 | Flutter, Riverpod, go_router, dio |
| 관리자 웹 | Next.js 15 (App Router), TanStack Query, shadcn/ui |
| DB / Auth / Realtime / Storage | Supabase (Postgres + Realtime + Storage) |
| 푸시 | Firebase Cloud Messaging |
| 모니터링 | Sentry |
| 호스팅 | Railway/Render (백엔드), Vercel (관리자 웹) |

---

## 시작

**처음 클론한 사람**: [`docs/ONBOARDING.md`](./docs/ONBOARDING.md) — 사전 설치 / 시크릿 받기 / 셋업 / 첫 실행 검증을 한 문서로.

폴더별 세부 가이드:
- 백엔드: [`backend/README.md`](./backend/README.md)
- 모바일: [`mobile/README.md`](./mobile/README.md)
- 관리자 웹: [`admin/README.md`](./admin/README.md)

---

## 문서

- [`docs/ONBOARDING.md`](./docs/ONBOARDING.md) — 새 팀원 첫 셋업
- [`docs/CONTRIBUTING.md`](./docs/CONTRIBUTING.md) — 피처 작업 라이프사이클 / PR 흐름
- [`docs/SCHEMA.md`](./docs/SCHEMA.md) — DB 스키마 + RLS 정책 + 테이블 owner
- [`docs/FEATURES.md`](./docs/FEATURES.md) — 38개 피처 → 작업 단위 매핑
- [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md) — 시스템 구조, 핵심 결정

---

## 개발 방법론

**Vertical slice**. 한 피처는 백엔드 `features/<name>/` + 앱 `features/<name>/` 한 쌍.
`core/`, `shared/`, DB 스키마는 메인 빌더만 손댐. 새 피처 시작은 `features/_template/` 복사.

**브랜치 모델**: `main`(프로덕션) / `dev`(개발 기본). 모든 작업 브랜치는 `dev`에서 분기 + `dev`로 PR. `main`은 메인 빌더가 release 시점에만 갱신.

상세는 `docs/CONTRIBUTING.md` 참조.
