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
│       └── <피처>/      # ★ 작업 영역
├── mobile/lib/
│   ├── core/         # 메인 빌더만.
│   └── features/
│       ├── _template/
│       └── <피처>/      # ★ 작업 영역
├── admin/            # 관리자 웹 (Next.js)
├── docs/             # 모든 정식 문서
└── _workspace/       # 메인 빌더 로컬 작업 폴더 (깃 X, 보지 마)
```

---

## 컨텍스트 우선순위

피처 작업 시 다음 순서로 컨텍스트 파악:

1. **현재 작업 `features/<폴더>/SPEC.md`** — 무엇을 만드는지, 어떤 인터페이스를 노출하는지
2. **`docs/SCHEMA.md`** — DB 테이블 / 컬럼 / RLS 정책 (DB 접근 시 필수)
3. **현재 폴더의 기존 코드** — 같은 패턴 따라 작성
4. **`backend/app/core/` / `mobile/lib/core/` 인터페이스** — 의존하는 함수 시그니처 확인 (수정 X)
5. **`docs/FEATURES.md`** — 다른 피처와의 의존 관계, 우선순위 배경
6. **다른 피처의 `SPEC.md`** — public 인터페이스 호출 시

읽지 말 것:
- `_workspace/` (메인 빌더 로컬 작업 공간, 깃에 없음)
- 다른 피처의 내부 구현 (SPEC.md의 public 인터페이스만)

---

## 새 피처 시작 절차

```bash
# 1. 템플릿 복사
cp -r backend/app/features/_template backend/app/features/<폴더>
cp -r mobile/lib/features/_template mobile/lib/features/<폴더>

# 2. SPEC.md 채움 (먼저!)
#    - API 엔드포인트
#    - 읽기/쓰기 테이블
#    - core/ 의존
#    - 비즈니스 룰
#    - 엣지 케이스
#    - 공개 인터페이스 (다른 피처가 호출 가능한 함수)

# 3. 구현
```

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
