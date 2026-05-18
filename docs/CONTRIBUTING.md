# 컨트리뷰팅 가이드

> 피처 컨트리뷰터(작업자) 대상.
> 메인 빌더 영역(`core/`, `shared/`, `migrations/`, `.github/`, `docs/`)은 별도 협의.

---

## TL;DR — 한 피처 끝내는 흐름

```
1. 이슈 할당받음            (메인 빌더가 GitHub 이슈로 작업 단위 부여)
2. features/_template 복사  → features/<내 피처>
3. SPEC.md 먼저 채움        (API/DB/엣지케이스)
4. 백엔드 + 앱 같이 구현    (한 사람이 양쪽 다)
5. PR 올림                  (PR 템플릿 체크리스트 채움)
6. 머지                     (squash)
```

상세는 아래.

---

## 1. 시작하기

### 1.1 환경 준비

```bash
# 레포 클론
git clone https://github.com/<org>/gihagochi.git
cd gihagochi

# 백엔드 (Python 3.12+)
cd backend
uv sync                         # 또는 pip install -e ".[dev]"

# 모바일 (Flutter 3.27+)
cd ../mobile
flutter pub get
dart run build_runner build     # freezed/json/riverpod 코드 생성

# 관리자 웹 (Node 20+)
cd ../admin
npm install

# 루트 (pre-commit 훅 활성화)
cd ..
pip install pre-commit && pre-commit install
```

### 1.2 환경 변수

각 폴더의 `.env.example` 복사 후 값 채움. **실제 키는 메인 빌더에게 요청.**

```bash
cp backend/.env.example backend/.env
cp mobile/.env.example mobile/.env
cp admin/.env.example admin/.env
```

### 1.3 dev 환경 검증

- 백엔드: `uvicorn app.main:app --reload` → `http://localhost:8000/health` 200
- 앱: `flutter run` → 빈 화면이라도 떠야 함
- 관리자: `npm run dev` → `http://localhost:3000` 진입

---

## 2. 작업 단위 받기

### 2.1 작업 단위란?

38개 피처를 **12개 작업 단위(`features/<폴더>`)** 로 묶음. 한 작업 단위는 한 사람이 한 번에 끝냄.

매핑 표는 [`docs/FEATURES.md`](./FEATURES.md) §2 참조.

### 2.2 할당 흐름

1. 메인 빌더가 GitHub 이슈로 작업 단위 할당 (이슈 템플릿: feature)
2. 이슈 본문의 **선행 기능 / 수용 기준 / 결정 필요 사항** 확인
3. 모르면 이슈 코멘트로 질문 — 코딩 시작 전에 풀기

### 2.3 브랜치

```bash
git checkout -b feature/<폴더-이름>
# 예: feature/auth, feature/chat_message
```

---

## 3. 피처 라이프사이클

### 3.1 명세 작성 (코딩 시작 전)

```bash
cp -r backend/app/features/_template backend/app/features/<내폴더>
cp -r mobile/lib/features/_template mobile/lib/features/<내폴더>
```

`SPEC.md`를 **먼저** 채움. AI에게 컨텍스트 줄 때 이 파일이 베이스.

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
```

### 3.2 구현 (바이브 코딩)

- AI에게 줄 컨텍스트:
  - `features/<폴더>/SPEC.md`
  - `features/<폴더>/` 전체
  - 필요한 `core/` / `shared/` 파일 (수정 X, 참조용)
  - DB 스키마 ([`docs/SCHEMA.md`](./SCHEMA.md))
- 백엔드 라우터 + Flutter 화면을 같은 사람이 진행 (인터페이스 협의 비용 0)
- `core/`에서 필요한데 없는 게 있으면 → **메인 빌더에게 핑** (직접 추가 금지)

### 3.3 PR 올리기

```bash
git add backend/app/features/<폴더> mobile/lib/features/<폴더>
git commit -m "feat(<폴더>): F-XXX 구현"
git push -u origin feature/<폴더-이름>
gh pr create
```

PR 템플릿 체크리스트:
- [ ] `SPEC.md` 채움
- [ ] `core/`, `shared/`, 다른 `features/` 수정 없음
- [ ] 마이그레이션 1개 이하 (있을 경우)
- [ ] 수동 테스트 시나리오 첨부

### 3.4 리뷰 / 머지

- 메인 빌더가 인터페이스 / 마이그레이션 영향만 확인
- 코드 디테일은 안 봄 (격리되어 있으니까)
- **squash merge**

### 3.5 AI 보조 작업 (바이브 코딩)

룰의 본체는 [`AGENTS.md`](../AGENTS.md). 본인 도구가 자동 로드 안 하면 수동 첨부.

| 도구 | 자동 로드 여부 | 본인이 할 일 |
|---|---|---|
| Claude Code | ✓ (`CLAUDE.md` → `@AGENTS.md`) | 없음 |
| Codex (CLI / Cloud) | ✓ (`AGENTS.md` 직접) | 없음 |
| Cursor | 부분 (`.cursor/rules/` 설정 시) | 미설정 시 `AGENTS.md` 수동 첨부 |
| Copilot | 부분 (`.github/copilot-instructions.md` 설정 시) | 미설정 시 수동 첨부 |
| 기타 (Aider, Windsurf, Cline 등) | 도구마다 다름 | 세션 시작 시 `AGENTS.md` 시스템 프롬프트로 첨부 |

**룰 위반 PR은 리뷰에서 reject** — CODEOWNERS와 CI 가드가 일부 잡지만, 룰을 알면 PR 만들기 전에 막힘.

AI에게 처음 컨텍스트 줄 때 권장 묶음:
1. `AGENTS.md`
2. `features/<내폴더>/SPEC.md`
3. `docs/SCHEMA.md` (DB 접근 시)
4. 호출하려는 `core/` 함수의 시그니처

---

## 4. 만지면 안 되는 것

### 4.1 메인 빌더 영역 (CODEOWNERS 보호)

```
backend/app/core/         # 인증/DB/Realtime/FCM/에러 등 공용 인프라
backend/app/shared/       # SQLAlchemy 모델 (테이블당 1파일)
backend/migrations/       # Alembic
mobile/lib/core/          # 앱 공용 인프라
admin/lib/                # 관리자 웹 공용
admin/middleware.ts
docs/                     # 모든 문서
.github/                  # 워크플로우 / 템플릿
backend/pyproject.toml    # 의존성
mobile/pubspec.yaml
admin/package.json
```

이 경로 변경 시 **메인 빌더 승인 필수**. 일단 이슈/PR 코멘트로 핑.

### 4.2 다른 컨트리뷰터의 `features/`

다른 사람 폴더 직접 수정 금지. 그 피처의 함수가 필요하면:

- `service.py`의 public 함수만 import
- 그 피처의 `SPEC.md` "공개 인터페이스" 섹션 확인
- 명시되지 않은 함수는 안 씀 (변경 가능성 있음)

---

## 5. 충돌 처리

| 상황 | 처리 |
|---|---|
| 다른 PR과 같은 마이그레이션 번호 충돌 | 늦은 PR이 `alembic merge`로 병합 |
| 다른 PR과 같은 테이블에 컬럼 추가 | 마이그레이션 분리하면 OK |
| `core/`에 새 함수 필요 | 메인 빌더에게 핑 → 메인 빌더가 추가 → rebase |
| 같은 `features/` 폴더 두 사람 작업 | 작업 단위 묶기 실패 — 한 사람에게 몰기 (메인 빌더와 협의) |

---

## 6. 코드 스타일

### 6.1 자동 적용 (pre-commit)

`pre-commit install` 했으면 커밋 시 자동 실행:
- Python: ruff (lint + format)
- Dart: `dart format`
- 공용: trailing whitespace / EOF / line ending

수동 실행: `pre-commit run --all-files`

### 6.2 명명

- 한국어 주석 OK (단, 의도/이유만 — WHAT은 코드로 표현)
- Python: snake_case, 함수/변수
- Dart: camelCase (변수/함수), PascalCase (클래스/위젯)
- TS: camelCase / PascalCase

### 6.3 함수 길이

긴 함수는 분리 (단일 책임). 화면 한 개 = 위젯 한 개로 다 박지 말고 sub-widget으로 쪼개기.

---

## 7. 테스트

### 7.1 백엔드

```bash
cd backend
pytest                                # 전체
pytest app/features/<폴더>            # 내 피처만
```

피처별 `tests/` 폴더에 최소 1개 테스트 (router 스모크). 비즈니스 로직 분기 있으면 service 테스트 추가.

### 7.2 모바일

```bash
cd mobile
flutter test
```

Riverpod controller / repository 테스트 권장. 위젯 테스트는 핵심 화면만.

### 7.3 수동 테스트

PR에 시나리오 첨부:

```
1. 로그인 화면 진입
2. 이메일 / 비번 입력 → 로그인 버튼
기대: 메인 페이지로 이동 + 응원 중인 아이돌 목록 표시
```

---

## 8. 도움 요청

- **DB 스키마 변경 필요**: 메인 빌더에게 핑 (스키마 변경은 메인 빌더만)
- **`core/` 새 기능 필요**: 동일
- **다른 피처와 인터페이스 협의**: 양쪽 컨트리뷰터 + 메인 빌더 3자
- **명세 모호**: 이슈 코멘트로 질문 (코딩 시작 전에)
- **버그 막힘**: PR로 일단 올리고 draft 상태에서 도움 요청

---

## 9. 자주 빠지는 함정

- **`core/` 무단 수정** → CODEOWNERS가 막음. 사전 합의 필수.
- **마이그레이션 2개 이상** → CI가 막음. 1 PR = 1 마이그레이션.
- **`SPEC.md` 안 쓰고 시작** → AI 컨텍스트가 흐려져서 결국 더 오래 걸림.
- **다른 피처 함수 그냥 import** → 그 피처가 리팩터되면 깨짐. SPEC.md 공개 인터페이스만.
- **테스트 없이 머지 요청** → 리뷰 거절. 최소 스모크 1개.
