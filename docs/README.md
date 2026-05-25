# docs/ — 문서 인덱스

> 이 폴더 안 문서가 각자 무엇이고, 누가 언제 봐야 하는지 한 장으로 정리.
> AI 작업 룰의 본체는 루트 [`AGENTS.md`](../AGENTS.md). 본 폴더는 **사람용 가이드 + AI가 컨텍스트로 읽는 명세** 모음.

---

## 빠른 인덱스

| 문서 | 대상 | 한 줄 요약 | 언제 보는가 |
|---|---|---|---|
| [ONBOARDING.md](./ONBOARDING.md) | 🧑 사람 | 새 팀원 첫 셋업 (도구 설치 → 시크릿 → 실행 검증) | 레포 클론 직후. **레포 처음 받았을 때 첫 진입점** |
| [CONTRIBUTING.md](./CONTRIBUTING.md) | 🧑 사람 | 피처 작업 라이프사이클 (이슈 → SPEC → 구현 → PR → 머지) | 피처 할당받았을 때 / 작업 흐름이 헷갈릴 때 |
| [GITHUB_OPS.md](./GITHUB_OPS.md) | 🧑 사람 | PR / CI / 머지 GitHub 운영 메커니즘 | PR 처음 올릴 때 / CI 깨졌을 때 |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | 🧑 사람 + 🤖 AI 컨텍스트 | **왜** 이렇게 설계했는가 (시스템 구조 + 핵심 결정) | 큰 그림 이해 필요 / 설계 결정 근거 찾을 때 |
| [SCHEMA.md](./SCHEMA.md) | 🤖 **AI 필수 컨텍스트** + 🧑 사람 | DB 테이블 / 컬럼 / RLS 정책 | **DB 접근 코드 작성 시 항상** (AGENTS.md 컨텍스트 우선순위 2위) |
| [FEATURES.md](./FEATURES.md) | 🧑 사람 + 🤖 AI 컨텍스트 | 38개 피처 명세 + 12개 작업 단위 매핑 + 의존 관계 | 피처 할당받기 직전 / 다른 피처와의 관계 확인 |
| [VSA.md](./VSA.md) | 🧑 사람 | Vertical Slice Architecture 채택 이유와 슬라이스 경계 정의 | "왜 폴더가 이렇게 잘려있지?" 의문 들 때 |
| [VSA_CHECKLIST.md](./VSA_CHECKLIST.md) | 🧑 사람 (주로 메인 빌더) | 하네스 갖춰졌나 + 12개 슬라이스 진행도 | 새 슬라이스 시작 전 인프라 확인 / 진행 점검 |
| [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) | 🧑 사람 | 셋업 / 배포 / Supabase / JWT / 어드민 운영 중 마주친 함정과 해결 | 셋업 / 검증 / 배포 중 막혔을 때 / 같은 함정 예방 |

---

## 대상별 읽는 순서

### 🧑 새 팀원 (레포 처음 받음)

1. 루트 [`README.md`](../README.md) — 프로젝트가 뭐 하는 건지
2. [ONBOARDING.md](./ONBOARDING.md) — 본인 PC 셋업
3. [CONTRIBUTING.md](./CONTRIBUTING.md) — 작업 흐름
4. (선택) [VSA.md](./VSA.md) — 폴더 구조 왜 이런지
5. 피처 할당받으면 → [FEATURES.md](./FEATURES.md)에서 본인 작업 단위 찾기

### 🤖 AI 에이전트 (Claude Code / Codex / Cursor / Copilot 등)

룰의 본체는 [`AGENTS.md`](../AGENTS.md) — 도구가 자동 로드. docs/ 폴더 문서들은 **컨텍스트로 던지는 명세**.

피처 작업 시 컨텍스트 우선순위 ([AGENTS.md](../AGENTS.md) §컨텍스트 우선순위):

1. 현재 작업 `features/<폴더>/SPEC.md`
2. **[SCHEMA.md](./SCHEMA.md)** (DB 접근 시 필수)
3. 현재 폴더의 기존 코드
4. `backend/app/core/` / `mobile/lib/core/` 인터페이스 (참조만, 수정 X)
5. **[FEATURES.md](./FEATURES.md)** (다른 피처 의존 / 우선순위 배경)
6. 다른 피처의 `SPEC.md` (public 인터페이스 호출 시)

읽지 말 것: `_workspace/` (메인 빌더 로컬, 깃 외부) / 다른 피처 내부 구현.

### 🧑 메인 빌더

위 전부 + [VSA_CHECKLIST.md](./VSA_CHECKLIST.md)로 하네스 / 진행도 추적.

---

## 문서가 아닌 곳에 있는 것

| 위치 | 내용 |
|---|---|
| 루트 [`AGENTS.md`](../AGENTS.md) | AI 작업 룰 본체 (절대 룰 5개, 컨텍스트 우선순위, 머지 전 체크리스트) |
| 루트 [`CLAUDE.md`](../CLAUDE.md) | Claude Code 진입점 (`@AGENTS.md` import만) |
| [`backend/AGENTS.md`](../backend/AGENTS.md) | 백엔드 stack-specific 룰 (FastAPI / SQLAlchemy / Alembic 패턴) |
| [`mobile/AGENTS.md`](../mobile/AGENTS.md) | 모바일 stack-specific 룰 (Flutter / Riverpod / go_router 패턴) |
| [`admin/AGENTS.md`](../admin/AGENTS.md) | 관리자 웹 stack-specific 룰 (Next.js 16 breaking changes 포함) |
| `backend/app/features/_template/SPEC.md` | 새 백엔드 피처 시작 시 복사할 양식 (확정된 계약) |
| `mobile/lib/features/_template/SPEC.md` | 새 모바일 피처 시작 시 복사할 양식 (확정된 계약) |
| [`feature-specs/`](../feature-specs/README.md) | **진화하는 요구사항 노트** (사용자가 자유 수정, AI 컨텍스트). 시작 트리거가 자동 생성 |
| `.github/PULL_REQUEST_TEMPLATE.md` | PR 생성 시 자동 본문 (체크리스트) |
| `.github/ISSUE_TEMPLATE/feature.md` | 피처 할당 이슈 자동 본문 |

---

## 문서 추가 / 수정 룰

- `docs/` 폴더는 **메인 빌더 영역** ([AGENTS.md §절대 룰](../AGENTS.md)). 컨트리뷰터는 직접 수정 금지.
- 수정 필요 시 이슈 / PR 코멘트로 메인 빌더에게 핑.
- 새 문서를 추가하면 본 인덱스(`docs/README.md`)에도 1줄 추가.
