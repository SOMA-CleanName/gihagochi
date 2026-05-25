# 운영 트러블슈팅

> 셋업/배포/검증 중 실제로 마주친 함정과 해결책을 누적 기록한다.
> 새 컨트리뷰터가 같은 함정에 빠지지 않도록 사례 기반으로 정리.
> 일반 셋업 가이드는 [`ONBOARDING.md`](./ONBOARDING.md), GitHub/CI는 [`GITHUB_OPS.md`](./GITHUB_OPS.md).

---

## 목차

- [환경 분리 / 배포](#환경-분리--배포)
  - [Railway / Vercel 이 main 브랜치만 watch — dev 머지가 production에 안 감](#railway--vercel-이-main-브랜치만-watch--dev-머지가-production에-안-감)
  - [Railway DATABASE_URL 이 Direct connection — `Network unreachable`](#railway-database_url-이-direct-connection--network-unreachable)
  - [Railway Pre-deploy command 미설정 — 마이그레이션 자동 적용 안 됨](#railway-pre-deploy-command-미설정--마이그레이션-자동-적용-안-됨)
- [Supabase Auth / JWT](#supabase-auth--jwt)
  - [`The specified alg value is not allowed` — Supabase 신규 프로젝트는 ECC default](#the-specified-alg-value-is-not-allowed--supabase-신규-프로젝트는-ecc-default)
  - [JWT secret rotation — Standby Key + Import existing secret 흐름](#jwt-secret-rotation--standby-key--import-existing-secret-흐름)
  - [SUPABASE_URL / ANON_KEY 짝 안 맞음 — 500 또는 invalid token](#supabase_url--anon_key-짝-안-맞음--500-또는-invalid-token)
  - [어드민 웹 role 게이트 — JWT user_metadata 아닌 profiles 테이블이 진실의 원천](#어드민-웹-role-게이트--jwt-user_metadata-아닌-profiles-테이블이-진실의-원천)
- [어드민 웹](#어드민-웹)
  - [`NEXT_PUBLIC_API_BASE_URL` 누락 — Server Action 이 localhost fallback](#next_public_api_base_url-누락--server-action-이-localhost-fallback)
  - [env 변경 후 자동 redeploy 안 됨 — 수동 Redeploy 필수](#env-변경-후-자동-redeploy-안-됨--수동-redeploy-필수)
- [백엔드 테스트](#백엔드-테스트)
  - [admin role JWT 헤더로 호출한 라우터 테스트가 CI(DB 없음)에서 실패](#admin-role-jwt-헤더로-호출한-라우터-테스트가-cidb-없음에서-실패)
- [Git / GitHub](#git--github)
  - [squash merge + `--delete-branch` 후 브랜치 라벨 사라짐 — 정상 동작](#squash-merge----delete-branch-후-브랜치-라벨-사라짐--정상-동작)

---

## 환경 분리 / 배포

### Railway / Vercel 이 main 브랜치만 watch — dev 머지가 production에 안 감

**증상**
- dev 에 PR 머지했는데 `gihagochi-production.up.railway.app` 의 동작은 그대로
- Railway Deployments 탭에 새 PR 들이 `SKIPPED — No changes to watched files` 로 표시
- Vercel Deployments 도 dev 머지가 production 으로 promote 안 됨

**원인**
- main(prod) / dev(개발) 분리 후 Railway / Vercel 의 watch branch 가 여전히 `main`
- MVP 단계에서 별도 prod 환경 없음 → 검증할 곳이 없음

**해결** (MVP 단계 — 단일 환경 운영)
- Railway: Service → Settings → Source → **Branch: `main` → `dev`**
- Vercel: Project → Settings → Git → **Production Branch: `main` → `dev`** + Domains 그대로
- 진짜 prod 분리는 베타 출시 직전에 [`ARCHITECTURE.md`](./ARCHITECTURE.md) §7 옵션 A 로 재구성

**참고**
- 이 결정은 `gihagochi-production` 이라는 이름의 환경이 사실상 dev 검증 환경으로 동작한다는 뜻
- 룰( [`AGENTS.md`](../AGENTS.md) 의 main/dev 분리)은 코드 브랜치 모델만 다루므로 배포 환경 매핑 변경과 무관

---

### Railway DATABASE_URL 이 Direct connection — `Network unreachable`

**증상**
```
OSError: [Errno 101] Network is unreachable
  File ".../asyncpg/connect_utils.py", line 969, in _create_ssl_connection
```
- 백엔드 라우터에서 DB 접근 시 500
- JWT 검증은 통과한 직후 첫 DB 쿼리에서 fail

**원인**
- DATABASE_URL 이 Direct connection (`db.<ref>.supabase.co:5432`) 으로 설정됨
- Supabase Direct connection 은 **IPv6 only**, Railway 컨테이너는 IPv4 only → 라우팅 불가
- Supabase Studio 화면이 Direct URL 을 default 로 노출해서 그대로 복사하면 빠지기 쉬움

**해결**
1. Supabase Studio → Project Settings → Database → **Connection string** 박스
2. 탭에서 **Session** 선택 (Direct / Transaction 아님)
3. URL 형식 확인:
   ```
   postgresql://postgres.<ref>:[PWD]@aws-X-<region>.pooler.supabase.com:5432/postgres
   ```
   - host 에 `pooler.supabase.com` 포함 ✅
   - user 가 `postgres.<ref>` 형태 (점 포함) ✅
   - port `5432` ✅
4. Railway Variables → `DATABASE_URL` 교체 → **Redeploy**

**구분법 한눈에**

| 항목 | Direct (❌ Railway 불가) | Session pooler (✅) |
|---|---|---|
| host | `db.<ref>.supabase.co` | `aws-X-<region>.pooler.supabase.com` |
| user | `postgres` | `postgres.<ref>` |
| port | 5432 | 5432 |

> Transaction pooler (port 6543) 는 prepared statement 제약 때문에 SQLAlchemy 기본 설정과 충돌. 본 프로젝트는 **Session mode 사용**.

---

### Railway Pre-deploy command 미설정 — 마이그레이션 자동 적용 안 됨

**증상**
- 새 Supabase 프로젝트에서 `relation "profiles" does not exist`
- 백엔드 헬스체크는 통과하지만 모든 DB 쿼리 실패

**원인**
- `backend/Dockerfile` 의 CMD 는 uvicorn 만 실행. `alembic upgrade head` 포함 안 됨 (의도)
- Railway Pre-deploy command 미설정 시 마이그레이션은 별도로 수동 실행해야 함

**해결**
1. Railway → Service → Settings → Deploy → **Pre-deploy Command**:
   ```
   alembic upgrade head
   ```
2. 저장 → 다음 배포부터 자동 실행
3. 즉시 적용 필요하면 **Redeploy** 한 번 트리거

**검증**
- 배포 로그에서 `Running pre-deploy: alembic upgrade head` + `INFO [alembic.runtime.migration] Running upgrade ... -> 0001_initial` 확인
- Supabase Studio SQL Editor:
  ```sql
  SELECT tablename FROM pg_tables
    WHERE schemaname='public' ORDER BY tablename;
  ```
  → 10개 테이블

---

## Supabase Auth / JWT

### `The specified alg value is not allowed` — Supabase 신규 프로젝트는 ECC default

**증상**
- 백엔드에서 401 + 메시지 `유효하지 않은 토큰: The specified alg value is not allowed`
- 이전엔 잘 되던 토큰이 새 dev Supabase 로 갈아탄 후 안 됨

**원인**
- Supabase 신규 프로젝트는 JWT signing key 가 **ECC (P-256)** default
- 백엔드 `core/auth.py` 의 PyJWT 는 `algorithms=["HS256"]` 만 허용 → mismatch

**해결 (단기 — 1차 fix)**
- 다음 [JWT secret rotation](#jwt-secret-rotation--standby-key--import-existing-secret-흐름) 흐름으로 HS256 Standby Key 를 생성·promote 한 뒤 그 secret 을 Railway 에 동기

**해결 (장기 — 권장)**
- `backend/app/core/auth.py` 를 **PyJWKClient + `algorithms=["ES256", "HS256"]`** 로 변경
- Supabase JWKS endpoint (`https://<ref>.supabase.co/auth/v1/.well-known/jwks.json`) 에서 공개키 자동 fetch
- 메인 빌더 영역 — `core/<설명>` prefix 별도 PR

---

### JWT secret rotation — Standby Key + Import existing secret 흐름

**언제 필요**
- ECC default 프로젝트를 HS256 으로 옮길 때
- HS256 secret 을 새로 갱신할 때 (보안 회전, 유출 의심 등)

**핵심 함정**
- Supabase 가 자동 생성한 HS256 secret 은 **외부에 노출하지 않음** → backend(외부 서비스)가 그 값을 알 수 없음
- 그래서 **본인이 생성한 secret 을 Import 해야** 양쪽이 같은 값을 공유 가능

**절차**
1. 로컬에서 강한 secret 생성:
   ```bash
   openssl rand -base64 64 | tr -d '\n' | tee /tmp/jwt_secret.txt
   ```
   출력값을 안전한 곳에 보관.
2. Supabase Studio → Project Settings → JWT Keys → **Create Standby Key**:
   - Algorithm: **HS256 (Shared Secret)**
   - **Import an existing secret** ✅ 체크
   - textarea 에 위 secret 붙여넣기
   - **Secret is already Base64 encoded** ❌ 미체크 (PyJWT 와의 호환을 위해)
   - Create
3. JWT Signing Keys 탭 → 새 standby 행 ⋮ → **Rotate keys** → CURRENT 로 promote
4. Railway → Variables → `SUPABASE_JWT_SECRET` = `/tmp/jwt_secret.txt` 값 → 저장 → **Redeploy**
5. 어드민 웹 / 모바일에서 **로그아웃 → 다시 로그인** (옛 키로 서명된 토큰은 무효, 새 키로 재발급 필요)

**Base64 체크박스 주의**
- ✅ 체크: Supabase 가 입력값을 base64 decode → raw bytes 로 HMAC
- ❌ 미체크: 입력값을 그대로 UTF-8 bytes 로 HMAC
- 백엔드 PyJWT 는 secret 을 그대로 UTF-8 bytes 로 처리 → **미체크 + 같은 문자열 Railway 에 입력**해야 일치

---

### SUPABASE_URL / ANON_KEY 짝 안 맞음 — 500 또는 invalid token

**증상**
- 어드민 웹 진입 시 Internal Server Error
- 또는 미들웨어가 통과해도 액션 호출 시 invalid token
- Vercel Logs 에 `Invalid JWT` / `AuthApiError` / 500 stack trace

**원인**
- env 변경 시 `NEXT_PUBLIC_SUPABASE_URL` 만 새 프로젝트로 바꾸고 `NEXT_PUBLIC_SUPABASE_ANON_KEY` 는 옛 프로젝트 값 그대로
- ANON_KEY 는 프로젝트별로 다른 JWT secret 으로 서명되므로 URL 과 한 쌍이어야 동작

**해결**
- 같은 프로젝트 Settings → API 페이지에서 **URL + anon key + service_role key** 를 한 번에 복사해 갱신
- 백엔드 (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_JWT_SECRET`, `DATABASE_URL`) 5개 모두 같은 프로젝트로 통일
- env 변경 후 **반드시 Redeploy** (env 만 바꾸면 이미 떠 있는 인스턴스에 반영 안 됨)

---

### 어드민 웹 role 게이트 — JWT user_metadata 아닌 profiles 테이블이 진실의 원천

**증상 (수정 전)**
- Supabase Studio Authentication → Add User 로 만든 admin 계정으로 로그인하면 항상 `/login?error=unauthorized`
- `profiles.role='admin'` 으로 직접 UPDATE 했어도 차단

**원인**
- 옛 `admin/lib/supabase/middleware.ts` 가 `user.app_metadata?.role ?? user.user_metadata?.role` 기반으로 체크
- Studio 에서 직접 생성한 사용자는 user_metadata.role 이 없으므로 undefined → 차단
- profiles 테이블의 role/status 와 JWT metadata 가 동기화 안 됨

**해결 (PR #36 으로 적용됨)**
- middleware 가 `profiles` 테이블을 SELECT 해서 `role='admin' AND status='active'` 검증
- 정지된 관리자(`status='suspended'`)도 같은 경로로 차단

**경로**
```ts
const { data: profile } = await supabase
  .from('profiles')
  .select('role, status')
  .eq('id', user.id)
  .maybeSingle();
if (!profile || profile.role !== 'admin' || profile.status !== 'active') {
  return NextResponse.redirect(url('/login?error=unauthorized'));
}
```

---

## 어드민 웹

### `NEXT_PUBLIC_API_BASE_URL` 누락 — Server Action 이 localhost fallback

**증상**
- 어드민 웹에서 승인 / 정지 등의 액션 클릭 시 즉시 실패
- 네트워크 탭에 `http://localhost:8000/admin/...` 호출 시도 (실패)

**원인**
- `admin/app/(admin)/.../_actions/actions.ts` 의 `API_BASE` 가 `process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:8000'`
- Vercel 에 env 가 설정 안 되어 있으면 fallback 값(localhost) 사용 → Vercel 서버에서 localhost 호출 = fail

**해결**
- Vercel → Settings → Environment Variables → **Production** 환경:
  ```
  NEXT_PUBLIC_API_BASE_URL = https://gihagochi-production.up.railway.app
  ```
- 저장 후 **Redeploy** 필수

**팁**
- Preview / Development env 에도 같이 추가해두면 PR preview 검증도 가능
- 향후 dev/prod Supabase + Railway 분리하면 환경별 다른 값 매핑

---

### env 변경 후 자동 redeploy 안 됨 — 수동 Redeploy 필수

**증상**
- 환경 변수만 바꿨더니 새 값이 반영 안 됨

**원인**
- Vercel 도 Railway 도 env 변경 자체로는 새 배포를 트리거하지 않음 (코드 변경만 trigger)

**해결**
- Vercel: Deployments → 최신 production → ⋮ → **Redeploy**
- Railway: Service → ⋮ → **Redeploy** (또는 빈 commit 푸시)

---

## 백엔드 테스트

### admin role JWT 헤더로 호출한 라우터 테스트가 CI(DB 없음)에서 실패

**증상**
- CI 의 backend job 에서:
  ```
  OSError: Multiple exceptions: [Errno 111] Connect call failed ('::1', 5432, 0, 0), [Errno 111] Connect call failed ('127.0.0.1', 5432)
  ```
- 헤더 없이 401 만 확인하는 테스트는 통과, admin role 헤더로 호출한 테스트만 실패

**원인**
- `AdminUser` 의존성이 `get_current_user` 를 호출하고 그 안에서 `profiles` SELECT
- CI 환경엔 DB 가 없어 connection 시도 자체에서 OSError

**해결**
- 헤더 있는 라우터 호출 + 라우터까지 도달해야 하는 검증은 `@pytest.mark.integration` 로 마킹 (CI 는 `-m "not integration"`)
- 또는 그런 테스트는 dev DB 가 살아있는 로컬에서만 실행
- 빈 사유 같은 Pydantic 검증을 라우터 통과 후에 확인하려면 dev 환경의 `make_fresh_user` + admin 승격까지 필요 → 향후 통합 테스트로 분리

**예방**
- 라우터 호출 테스트 작성 시: "이 의존성 체인 안에서 DB 가 필수인가" 점검. 필수면 `@pytest.mark.integration`.

---

## Git / GitHub

### squash merge + `--delete-branch` 후 브랜치 라벨 사라짐 — 정상 동작

**증상**
- 머지된 PR 의 브랜치가 git GUI 그래프에서 라벨조차 안 보임
- "내 작업이 사라진 것 같다"는 혼란

**원인**
- 본 레포의 머지 정책 = **squash merge** ([CONTRIBUTING.md §3.4](./CONTRIBUTING.md))
- squash 머지는 여러 commit 을 1 개로 압축 → git 그래프상 분기 흔적 없음 (의도)
- `gh pr merge --squash --delete-branch` 옵션으로 머지 후 원격 브랜치 자동 삭제

**실제로는**
- ✅ **PR 페이지(`github.com/.../pull/<N>`) 에 squash 전 원본 commit 전체 보존** — 머지 경과의 진실의 원천
- ✅ dev 의 squash commit 메시지에 `(#PR번호)` 포함되어 PR 추적 가능
- ❌ git 그래프상 분기 모양이 안 보이는 것은 squash 정책의 정상 결과 (단점이라기보다 트레이드오프)

**옛 PR 브랜치 라벨이 그래프에 보인다면**
- 머지 후 `--delete-branch` 안 한 잔재. 안전하게 삭제:
  ```bash
  gh api repos/<org>/<repo>/branches --paginate -q '.[].name' \
    | grep -vE '^(dev|main)$' \
    | xargs -I{} gh api -X DELETE repos/<org>/<repo>/git/refs/heads/{}
  git fetch --prune
  ```

**분기 흔적을 그래프에 남기고 싶다면**
- 머지 정책을 `--no-ff` (merge commit) 로 바꾸면 됨
- 트레이드오프: history 노이즈 ↑, revert 시 `-m` 인자 필요
- 본 레포는 squash 채택 중

---

## 새 항목 추가 가이드

새 트러블슈팅을 추가할 때 다음 형식 유지:

```markdown
### <한 줄 증상 또는 에러 메시지>

**증상**
- 실제 본 로그 / 메시지 / 화면

**원인**
- 왜 그런지 (가능하면 코드 / 설정 위치 인용)

**해결**
- 구체 단계 (1, 2, 3...)

**참고 / 예방** (선택)
```

목차에도 새 항목 한 줄 추가.
