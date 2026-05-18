# GitHub 운영 — 피처 컨트리뷰터용

> PR 만들고 CI 통과시켜서 머지하기까지 필요한 운영 지식.
> 인프라/Secrets/배포 셋업 자체는 메인 빌더 영역.
>
> 사람용 라이프사이클은 [`CONTRIBUTING.md`](./CONTRIBUTING.md). 이 문서는 그 위에서 GitHub UI/CI 동작 메커니즘.

---

## 1. PR 라이프사이클

### 1.1 작업 시작

```powershell
# 최신 main 동기화
git switch main
git pull

# 브랜치 생성 — 컨벤션 권장
git switch -c <type>/<설명>
# type: feat | fix | chore | refactor | test | docs | style
# 예: feat/auth, fix/login-validation, docs/api-spec
```

`main`에는 **직접 push 불가** (branch protection). 항상 별도 브랜치에서 PR.

### 1.2 작업 + push

```powershell
# 작업 후
git add <파일>
git commit -m "feat(auth): F-001 회원가입 라우터"
git push -u origin <브랜치명>
```

push가 성공하면 출력에 PR 생성 URL이 따라옴:
```
remote: Create a pull request for '<브랜치>' on GitHub by visiting:
remote:      https://github.com/SOMA-CleanName/gihagochi/pull/new/<브랜치>
```

### 1.3 PR 생성

웹 또는 `gh` CLI.

**웹**:
- URL 열기 → 제목/본문 작성 → "Create pull request" 클릭
- PR 템플릿(`.github/PULL_REQUEST_TEMPLATE.md`)이 자동 채워짐 → 체크리스트 모두 채울 것

**gh CLI**:
```powershell
gh pr create --title "feat(auth): F-001 회원가입" --body "..."
```

### 1.4 CI 자동 트리거

PR 생성/업데이트 즉시 3개 워크플로우 실행 (§2 참조).

머지 가능 조건:
- [ ] 모든 **Required status checks** 통과
- [ ] **base branch (main)에 fresh** — outdated 시 "Update branch" 버튼 표시
- [ ] (현재 비활성) Required approvals = 0 — 승인 불필요

### 1.5 머지

CI 그린 → **Squash and merge** 권장:
- 커밋 메시지 한 줄로 압축됨 → `main` 히스토리 깔끔
- "Merge commit"은 `Require linear history` 룰로 비활성

### 1.6 머지 후 정리

```powershell
git switch main
git pull
git branch -d <머지된 브랜치>
```

원격 브랜치는 GitHub UI에서 자동 삭제 옵션 또는:
```powershell
git push origin --delete <브랜치명>
```

---

## 2. CI 워크플로우 — 각각 뭘 하는지

`.github/workflows/` 아래 3개 파일.

### 2.1 `ci.yml` — 빌드 + 테스트

**트리거**: `main` push, `main` 대상 PR

**구조**: `detect-changes` job이 paths-filter로 변경 영역 감지 → backend/mobile/admin job 중 변경된 것만 실행.

| Job | 도구 | 검증 항목 |
|---|---|---|
| `backend` | Python 3.13 + uv-like | `ruff check` / `ruff format --check` / pytest (`-m "not integration"`) |
| `mobile` | Flutter 3.41 | `pub get` / build_runner / `flutter analyze` / `flutter test` |
| `admin` | Node 20 | `npm ci` / eslint / `tsc --noEmit` / `next build` |

**왜 paths-filter**: 모노레포라 mobile만 수정해도 backend job이 도는 게 낭비. 변경 폴더만 빌드.

**Required status check** 등록됨 → 통과 못하면 머지 버튼 비활성.

### 2.2 `guard.yml` — 메인 빌더 영역 변경 경고

**트리거**: PR 생성/업데이트

**동작**: 다음 경로가 PR diff에 포함되면 자동 PR 코멘트 + `touches-core` 라벨 부착.
```
backend/app/core/, backend/app/shared/, backend/migrations/
mobile/lib/core/
admin/lib/, admin/middleware.ts, admin/proxy.ts
docs/, .github/
backend/pyproject.toml, mobile/pubspec.yaml, admin/package.json
```

**fail 시키지는 않음** — 시각적 경고만. 실제 차단은 CODEOWNERS가 처리(§5).

### 2.3 `migrations.yml` — PR당 마이그레이션 1개 강제

**트리거**: `backend/migrations/versions/` 변경된 PR

**동작**:
- **추가된** 마이그레이션 파일이 2개 이상 → **CI fail**
- 기존 마이그레이션 *수정*은 warning만 (이미 다른 환경에 적용된 후라면 위험)

**룰의 근거**: 1 PR = 1 마이그레이션은 `AGENTS.md` 절대 룰 3번.
2개 이상 필요하면 PR 나누거나 메인 빌더와 협의.

---

## 3. PR에서 자주 보는 상태/메시지

### "Some checks haven't completed yet"
CI 도는 중. 보통 2~6분. 너무 오래(15분+) 멈춰있으면 GitHub Actions 탭에서 로그 확인.

### "All checks have passed"
정상. 머지 가능.

### "Required check 'backend' is expected"
`backend` job이 **paths-filter로 skip**됐는데 Required check에는 등록됨.

대처: backend 영역 변경 없는 PR이라도 빈 commit 하나 더해서 backend job 트리거. 또는 메인 빌더에게 Required check에서 빼달라고 요청.

### "This branch is out-of-date with the base branch"
main이 그 사이 업데이트됨. UI의 **"Update branch"** 버튼 또는:
```powershell
git switch <브랜치>
git pull --rebase origin main
git push --force-with-lease
```

`--force-with-lease`는 안전한 force (남이 push한 거 있으면 거부). 그냥 `--force`는 X.

### "⚠ 메인 빌더 영역이 변경됨" PR 코멘트
`guard.yml`이 단 코멘트. 본인 작업이 보호 경로 건드렸으면:
- 정말 필요한지 재검토
- 필요하면 PR 본문에 사유 추가 + 메인 빌더에게 핑

### "Review required by Code Owners"
보호 경로 수정 시 CODEOWNERS에 등록된 사람의 승인 필요 (메인 빌더).
- 현재 Required approvals = 0이지만 **Code Owner 리뷰 룰은 별개**
- 메인 빌더에게 리뷰 요청 (PR 우측 Reviewers → 요청)

### Vercel "Deployment failed" 빨간 X
Vercel이 PR 프리뷰 배포 시도하다 실패. **Required check 아니면 머지 가능**.
원인 대부분: Vercel Root Directory 설정 안 됨, Env 변수 누락 — 메인 빌더 관할.

### "Merge button is disabled"
다음 중 하나:
- CI 진행 중
- CI 실패 (수정 필요)
- Base outdated (Update branch)
- Required Code Owner 승인 대기

UI에 어떤 게 막고 있는지 표시됨. 읽기.

---

## 4. CI 실패 디버깅

### 4.1 backend ruff 실패

```
Error: Process completed with exit code 1.
```

로그에서 `ruff check` 또는 `ruff format --check`를 찾아 어느 파일/룰인지 확인.

**해결**:
```powershell
cd backend
python -m ruff check . --fix         # 자동 수정 가능한 lint
python -m ruff format .              # 자동 포맷
git add -u && git commit -m "style: ruff fix"
git push
```

### 4.2 backend pytest 실패

```
FAILED app/features/<폴더>/tests/test_router.py::test_X - <에러>
```

자주 보는 원인:
- **DB 연결 시도** → 해당 테스트에 `@pytest.mark.integration` 빠짐. CI는 `-m "not integration"`로 실행.
- **import 에러** → 누락된 의존성. `backend/pyproject.toml`에 추가 (메인 빌더 승인 필요).

로컬 재현:
```powershell
cd backend
pytest -x --tb=short -m "not integration"
```

### 4.3 mobile build_runner 실패

```
Skipping ... Conflicting outputs
```

```powershell
cd mobile
dart run build_runner build --delete-conflicting-outputs
```

### 4.4 mobile flutter analyze 실패

대부분 unused import / unused variable / lint 위반.
```powershell
cd mobile
flutter analyze
# 보고된 라인 수정
dart format .
```

### 4.5 admin tsc / next build 실패

```powershell
cd admin
npm run typecheck   # tsc 단독
npm run build       # next build
```

### 4.6 migration-count 실패

```
::error::PR에 마이그레이션이 2개 추가됨. AGENTS.md 절대 룰 3번
```

PR을 두 개로 나누거나, 한 마이그레이션 파일에 합치기.

---

## 5. CODEOWNERS — 누가 어디 오너인지

`.github/CODEOWNERS` 발췌 (현재 상태):

| 경로 | 오너 |
|---|---|
| `backend/app/core/`, `backend/app/shared/`, `backend/migrations/` | `@Chelly142` (메인 빌더) |
| `mobile/lib/core/` | `@Chelly142` |
| `admin/lib/`, `admin/middleware.ts` | `@Chelly142` |
| `docs/`, `.github/` | `@Chelly142` |
| `backend/pyproject.toml`, `mobile/pubspec.yaml`, `admin/package.json` | `@Chelly142` |

PR이 위 경로를 건드리면 GitHub가 자동으로 메인 빌더를 reviewer로 할당.

### 보호 경로를 만져야 할 때

1. **만지기 전에** 이슈 또는 메시지로 메인 빌더에게 핑 (왜 필요한지)
2. 메인 빌더가 PR을 직접 만들거나, 본인 PR에 변경을 포함하도록 협의
3. PR 본문에 사유 명시

### 본인이 보호 경로 오너인 경우 (메인 빌더)

본인이 만든 PR도 본인이 승인 가능하지만, **본인이 push한 가장 최근 커밋은 본인 승인 무효** (`Require approval of the most recent reviewable push` 룰). 한 번 더 다른 사람 승인이 필요할 수도 있음.

---

## 6. 금지 / 주의 행동

### 자동 차단됨
- `main` 직접 push → `GH013: Repository rule violations found`
- `main` 강제 push / 삭제 → 동일
- 마이그레이션 2개 이상 한 PR → `migrations.yml`이 fail

### CI는 안 막지만 룰 위반 (리뷰에서 reject)
- `git commit --no-verify` (pre-commit hook 우회)
- 보호 경로 수정 후 사유 미기재
- `SPEC.md` 없이 피처 폴더 만들기
- 다른 피처 폴더의 internal 함수 import

### 안전 패턴
- 모르겠으면 **draft PR**로 일단 올리고 메인 빌더에게 핑
- 큰 변경은 작은 PR로 쪼개기 (리뷰 빠르고 충돌 적음)
- Force push 필요 시 `--force-with-lease` 사용

---

## 7. 관련 자료

| 문서 | 다룸 |
|---|---|
| [`AGENTS.md`](../AGENTS.md) | AI/사람 공용 절대 룰 5개 |
| [`docs/CONTRIBUTING.md`](./CONTRIBUTING.md) | 피처 작업 라이프사이클 + PR 본문 양식 |
| [`docs/ONBOARDING.md`](./ONBOARDING.md) | 처음 클론 후 셋업 |
| `.github/CODEOWNERS` | 오너 매핑 (소스 of truth) |
| `.github/workflows/*.yml` | CI 워크플로우 정의 |

---

## 8. 막혔을 때

1. PR 페이지의 빨간 X 클릭 → "Details" → 실패 로그 확인
2. 이 문서 §4 디버깅 표 매칭
3. 그래도 모르면 PR 코멘트로 메인 빌더에게 핑 + 로그 전문 첨부
