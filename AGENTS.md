# AGENTS.md — AI 에이전트 작업 룰

이 파일은 본 레포에서 AI 코딩 에이전트(Claude Code, Codex, Cursor 등)가 따라야 할 룰의 본체.
사람용 가이드는 [`docs/CONTRIBUTING.md`](./docs/CONTRIBUTING.md). 룰은 동일하되 본 문서가 더 짧고 강함.

---

## 절대 룰 (위반 시 작업 중단)

1. **`features/<폴더>/` 외부 수정 금지**. 다음 경로는 메인 빌더 영역:
   - `backend/app/core/`, `backend/app/shared/`, `backend/migrations/`
   - `mobile/lib/core/`
   - `admin/lib/`, `admin/middleware.ts`
   - `docs/`, `.github/`
   - `backend/pyproject.toml`, `mobile/pubspec.yaml`, `admin/package.json`
   - 위 경로 변경이 필요하면 **사용자에게 먼저 알리고 멈출 것**. 임의 추가 금지.
   - **예외**: `feature-specs/<본인 피처>.md` — 요구사항 노트는 본인 피처 한정 자유 수정.

2. **`SPEC.md` 없이 코드 작성 시작하지 말 것**. 새 피처 시작 시 `features/_template/` 복사 → `SPEC.md` 먼저 채움 → 그 다음 구현.

3. **마이그레이션은 PR당 1개 이하**. 2개 이상 필요하면 사용자에게 보고.

4. **다른 피처 폴더 직접 수정 금지**. 함수가 필요하면 그 피처 `service.py`의 public 함수만 import. `SPEC.md`의 "공개 인터페이스" 섹션에 명시되지 않은 함수는 호출 안 함.

5. **DB 스키마 변경 금지**. `SCHEMA.md` 수정이나 새 마이그레이션 작성 전 사용자 승인 필수.

---

## 디렉토리 지형

```
gihagochi/
├── backend/app/
│   ├── core/         # 메인 빌더만. 호출은 OK, 수정 X.
│   ├── shared/       # 동일.
│   └── features/
│       ├── _template/   # 새 피처 시작점 (복사)
│       └── <피처>/      # ★ 작업 영역 (SPEC.md = 확정된 계약)
├── mobile/lib/
│   ├── core/         # 메인 빌더만.
│   └── features/
│       ├── _template/
│       └── <피처>/      # ★ 작업 영역
├── admin/            # 관리자 웹 (Next.js)
├── feature-specs/    # ★ 진화하는 요구사항 노트 (본인 피처 자유 수정)
│   ├── _template.md
│   └── <피처>.md
├── docs/             # 모든 정식 문서
└── _workspace/       # 메인 빌더 로컬 작업 폴더 (깃 X, 보지 마)
```

---

## 컨텍스트 우선순위

피처 작업 시 다음 순서로 컨텍스트 파악:

1. **`feature-specs/<폴더>.md`** — 사용자가 적은 **최신 요구사항/결정/미정 사항** (진화 중)
2. **`features/<폴더>/SPEC.md`** — 무엇을 만드는지, 어떤 인터페이스를 노출하는지 (확정된 계약)
3. **`docs/SCHEMA.md`** — DB 테이블 / 컬럼 / RLS 정책 (DB 접근 시 필수)
4. **현재 폴더의 기존 코드** — 같은 패턴 따라 작성
5. **`backend/app/core/` / `mobile/lib/core/` 인터페이스** — 의존하는 함수 시그니처 확인 (수정 X)
6. **`docs/FEATURES.md`** — 다른 피처와의 의존 관계, 우선순위 배경
7. **다른 피처의 `SPEC.md`** — public 인터페이스 호출 시

> `feature-specs/<폴더>.md`의 **미정 사항**을 자체 판단으로 코드화 금지. 사용자 결정 → SPEC.md 승격 → 그 다음 구현.

읽지 말 것:
- `_workspace/` (메인 빌더 로컬 작업 공간, 깃에 없음)
- 다른 피처의 내부 구현 (SPEC.md의 public 인터페이스만)

---

## 워크플로우 자동화 (트리거 기반)

사용자가 아래 트리거를 말하면 **이 절차를 순차 수행**. 각 단계 결과는 1줄로 사용자에게 보고. 단계 묶어서 통째 진행 금지 — 한 단계 실패하면 즉시 멈추고 보고.

### 시작 트리거

키워드 예: `"<피처명> 시작할게"`, `"F-019 시작"`, `"auth 시작"`, `"새 피처 auth"`

피처명은 자연어 OK (`인증`, `auth`, `F-001`). 모호하면 [`docs/FEATURES.md`](./docs/FEATURES.md) §2 매핑 표에서 후보 1~3개 제시하고 사용자 확정.

1. **사전 검증**
   - `git status` → working tree dirty면 stash 제안 후 중단
   - 현재 브랜치가 main 아니면 사용자 확인 ("X 브랜치 두고 main으로 전환?")
2. **main 동기화** — `git switch main && git pull`
3. **폴더명 + F-번호 확정** — [`docs/FEATURES.md`](./docs/FEATURES.md) §2로 매핑. 모호하면 후보 제시
4. **브랜치 생성** — `git switch -c feature/<폴더-이름>`
5. **템플릿 복사** — 작업 단위에 포함된 stack만:
   ```bash
   cp -r backend/app/features/_template backend/app/features/<폴더>     # 백엔드 작업 시
   cp -r mobile/lib/features/_template mobile/lib/features/<폴더>       # 모바일 작업 시
   cp feature-specs/_template.md feature-specs/<폴더>.md                 # 요구사항 노트 (항상)
   ```
6. **요구사항 노트 작성 안내** — `feature-specs/<폴더>.md` 열고 사용자에게 한 줄 목표 + 요구사항 적으라고 요청. 적힌 만큼만 다음 단계로 보냄.
7. **SPEC.md 작성 안내** — 요구사항 중 확정된 항목을 `features/<폴더>/SPEC.md`(계약)로 옮김. **SPEC.md 빈 채로 구현 코드 작성 금지** (절대 룰 2)
8. SPEC.md 채워지면 → 구현 단계로. 작업 중 새 요구 떠오르면 `feature-specs/<폴더>.md`에 먼저 적고 → 합의 후 SPEC.md 갱신.

### 완료 트리거

키워드 예: `"작업 완료"`, `"PR 올려"`, `"끝났어"`, `"머지 준비"`

1. **자동 셀프 체크** (아래 "머지 전 셀프 체크" 항목 자동 실행):
   - SPEC.md 필수 섹션(API / DB / 비즈니스 룰)이 비어있지 않은가
   - `feature-specs/<폴더>.md`의 **Open Questions** 가 비어있는가 (미정 남기고 머지 X)
   - `git diff --name-only main...HEAD`가 `features/<폴더>/` + `feature-specs/<폴더>.md`만 포함하는가
   - 마이그레이션 카운트 ≤ 1 (`backend/migrations/versions/` 신규 파일)
   - 피처 폴더에 테스트 파일 ≥ 1개
   - 위반 항목 있으면 즉시 보고 후 중단 — 사용자가 고치고 트리거 재호출
2. **변경사항 요약** — `git diff --stat` + 신규 파일 목록 + 마이그레이션 유무 출력
3. **사용자 확인 brake** — "위 변경으로 PR 만든다. OK?" 응답 대기. **OK 전엔 commit/push 금지**
4. **실행** (OK 받은 후):
   ```bash
   git add backend/app/features/<폴더> mobile/lib/features/<폴더> feature-specs/<폴더>.md
   git commit -m "feat(<폴더>): F-XXX 구현"
   git push -u origin feature/<폴더-이름>
   gh pr create   # PR 템플릿 자동 적용
   ```
5. **PR URL 보고**

### 인지 트리거 — 메인 빌더 영역 변경 필요 발견 (자동)

피처 작업 중 다음을 인지하면 **즉시 멈추고 보고**. 자체 판단으로 메인 빌더 영역 손대지 말 것 (절대 룰 1).

발견 케이스:
- 호출하려는 `core.X` / `shared.Y` 가 없거나 시그니처 안 맞음
- `shared/models` 에 컬럼/테이블 추가 필요
- migration 작성 필요 (절대 룰 5 — DB 스키마 변경)
- `docs/SCHEMA.md` 갱신 필요
- 의존성 추가 필요 (pyproject.toml / pubspec.yaml / package.json)
- `.github/`, CI 설정 변경 필요

보고 양식:

```
[메인 빌더 영역 변경 필요]
  영역: <core | shared | infra | docs | ...>
  필요한 것: <구체 설명>
  이유: <피처 어디서 막혔는지>

권장 흐름:
  1. 현재 작업 WIP commit + push (안 잃게)
  2. 메인 빌더 영역 변경을 별도 브랜치(<prefix>/<설명>)로 선 머지
  3. 본 feature 브랜치 rebase 후 작업 재개

다음 행동? ("분리 시작" / "기다림" / "다른 부분 먼저")
```

### 분리 트리거 — 메인 빌더 영역 변경 시작

키워드 예: `"core 작업 시작"`, `"shared 변경"`, `"migration 분리"`, `"infra"`, `"docs 정정"`

브랜치 prefix 매핑:

| 영역 | prefix | 포함 경로 |
|---|---|---|
| backend/mobile 인프라 | `core/<설명>` | `backend/app/core/`, `mobile/lib/core/` |
| DB 스키마 + 모델 | `shared/<설명>` | `backend/app/shared/` + 동반 migration 1개 |
| 관리자 웹 인프라 | `admin-core/<설명>` | `admin/lib/`, `admin/middleware.ts`, `admin/proxy.ts` |
| CI / 의존성 / 환경 | `infra/<설명>` | `.github/`, `pyproject.toml`, `pubspec.yaml`, `package.json` |
| 문서 정정 | `docs/<설명>` | `docs/` |
| 긴급 버그 픽스 | `fix/<설명>` | 영역 무관, hotfix용 |

절차:
1. **WIP 보존** — 현재 feature 브랜치라면:
   ```bash
   git add -A && git commit -m "wip: <간단 설명>"
   git push   # 안전망
   ```
2. **main 동기화** — `git switch main && git pull`
3. **분리 브랜치 생성** — `git switch -c <prefix>/<설명>`
4. **변경 작업** — 해당 영역만. 다른 영역 손대지 말 것.
5. **셀프 체크** — diff가 해당 prefix 영역만 포함하는가
6. **사용자 brake** → commit/push/`gh pr create`
7. **PR 머지 대기** — 머지 후 → rebase 트리거로 자동 진행 안내

### rebase 트리거 — 메인 빌더 영역 PR 머지 후 본 작업 복귀

키워드 예: `"rebase"`, `"main 받아와"`, `"피처로 돌아가기"`

1. **현재 브랜치 확인** — feature/<폴더>가 아니면 사용자 확인
2. **WIP 처리** — dirty면 stash
3. **rebase** — `git fetch origin && git rebase origin/main`
4. **충돌 발생 시** — 즉시 중단 보고. 자체 해결 금지 (사용자에게 충돌 파일 + 컨텍스트 제시)
5. **정상 완료** — `git push --force-with-lease` (사용자 OK 받은 후만)
6. **WIP 복원** — stash pop (했을 시)

### 트리거 외 — 작업 중 인터럽트

- `"멈춰"` / `"중단"` → 현재 단계 멈춤. 진행 상황 보고 후 다음 지시 대기
- `"브랜치 버려"` → 사용자 명시 확인 후 `git switch main && git branch -D feature/<폴더>` (절대 자체 판단 금지)

---

## SPEC.md 양식

```markdown
# F-XXX 기능명

## API
- METHOD /path - 설명

## DB
- 읽기: messages, profiles
- 쓰기: message_reads

## 의존
- core.auth.get_current_user
- core.realtime.broadcast_to_idol_topic

## 비즈니스 룰
- ...

## 엣지 케이스
- ...

## 공개 인터페이스 (다른 피처가 호출 가능)
- service.get_message_by_id(id) -> Message | None
```

---

## 머지 전 셀프 체크 (PR 올리기 전)

- [ ] `features/<폴더>/SPEC.md` 채워짐
- [ ] `git diff` 결과가 `features/<폴더>/`만 포함 (메인 빌더 영역 0)
- [ ] 마이그레이션 1개 이하
- [ ] 테스트 1개 이상 (router 스모크)
- [ ] 한국어 주석은 의도/이유만 (코드로 표현 가능한 WHAT은 적지 말 것)
- [ ] PR 본문에 수동 테스트 시나리오 첨부

위반 항목 있으면 사용자에게 보고 후 수정.

---

## 코드 스타일

- **주석**: 한국어. 의도/이유만. WHAT은 코드로 표현.
- **함수 길이**: 단일 책임. 길어지면 분리.
- **Python**: snake_case, 4-space indent, ruff가 포맷
- **Dart**: camelCase (변수/함수), PascalCase (클래스/위젯), 2-space indent, dart format
- **TypeScript**: camelCase / PascalCase, 2-space indent, prettier

자동 적용은 pre-commit이 처리. 직접 신경 쓸 필요 X.

---

## 충돌 / 막힘 시 사용자에게 물을 것

다음은 자체 판단 금지, 반드시 사용자에게 확인:

- `core/`, `shared/`, 마이그레이션, 다른 `features/` 수정이 필요한 경우
- DB 스키마 변경
- `SPEC.md`에 명세되지 않은 비즈니스 룰 결정
- 의존성 추가 (pyproject.toml / pubspec.yaml / package.json)
- 환경 변수 신규 추가
- API 엔드포인트 시그니처 변경 (다른 피처가 호출 중일 수 있음)

---

## 더 자세한 정보

- [`docs/CONTRIBUTING.md`](./docs/CONTRIBUTING.md) — 사람용 라이프사이클 + 환경 셋업
- [`docs/FEATURES.md`](./docs/FEATURES.md) — 38개 피처 명세 + 작업 단위 매핑
- [`docs/SCHEMA.md`](./docs/SCHEMA.md) — DB 스키마 + RLS *(작성 예정)*
- [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md) — 시스템 구조 / 핵심 결정 *(작성 예정)*
