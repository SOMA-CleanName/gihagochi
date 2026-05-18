# 온보딩 — 새 팀원용 첫 셋업

> 레포 처음 받은 사람용. 모든 스택(backend / mobile / admin)을 본인 PC에서 띄우는 데까지.
> 작업 흐름(이슈 받기 / PR / 코드 스타일)은 별도 — [`CONTRIBUTING.md`](./CONTRIBUTING.md).

---

## 0. TL;DR

```
1. 필요한 도구 설치 (§1)
2. 메인 빌더에게 시크릿 받기 (§2)
3. 각 폴더 셋업: backend → admin → mobile (§3)
4. 첫 실행 검증 (§4)
5. 인프라 룰 숙지: 직접 push 금지, PR 필수 (§5)
```

---

## 1. 사전 설치

플랫폼 무관 공통:

| 도구 | 최소 버전 | 확인 |
|---|---|---|
| Git | 2.40+ | `git --version` |
| Python | **3.12** 이상 (3.13 권장) | `python --version` |
| Node.js | **20** 이상 | `node --version` |
| Flutter | **3.27** 이상 (3.41 권장) | `flutter --version` |
| Dart | Flutter에 포함됨 (3.8+) | `dart --version` |

설치 안내:
- Python: https://www.python.org/downloads/
- Node: nvm 또는 https://nodejs.org/
- Flutter: https://docs.flutter.dev/get-started/install

### Windows 전용

- **PowerShell 7+** 권장 (`winget install Microsoft.PowerShell`)
- **Long path support** 활성화 (관리자 PowerShell):
  ```powershell
  New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
    -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
  ```
- **Git autocrlf** 권장 셋업: `git config --global core.autocrlf input`
- Cygwin/MinGW 충돌 덤프(`*.stackdump`)는 자동 ignore됨

### macOS

- Xcode + Command Line Tools (iOS 빌드 필요 시)
- `brew install python@3.13 node flutter`

### 모바일 빌드용 추가 (개발 중에는 일단 한 플랫폼만)

- **Android Studio** — Android SDK + 에뮬레이터 또는 실기기
  - 디바이스 USB 디버깅 ON, 첫 연결 시 "USB 디버깅 허용" 다이얼로그 수락
- **Xcode** — iOS 개발 시 (Mac만 가능)

---

## 2. 시크릿 받기

**`.env.example`은 양식만 있음. 실제 값은 메인 빌더에게 별도 요청.**

받아야 할 묶음:

### 백엔드 (`backend/.env`)
- `DATABASE_URL` — Supabase dev 프로젝트의 Session Pooler URL
- `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_JWT_SECRET`
- `SENTRY_DSN` — gihagochi-backend Sentry 프로젝트 DSN
- `FCM_SERVICE_ACCOUNT_JSON` 또는 `FCM_SERVICE_ACCOUNT_PATH` (둘 중 하나)

### 모바일 (`mobile/.env` 또는 `--dart-define`)
- `SUPABASE_URL`, `SUPABASE_ANON_KEY`
- `API_BASE_URL` — PROD: `https://gihagochi-production.up.railway.app`
- `SENTRY_DSN` — gihagochi-mobile Sentry 프로젝트 DSN
- `google-services.json` (FCM 사용 시) — Firebase Console에서 받아 `mobile/android/app/`에 배치

### 어드민 (`admin/.env.local`)
- `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `NEXT_PUBLIC_SENTRY_DSN`

> 시크릿은 절대 커밋 금지. `.env`, `.env.local`, `service-account*.json`, `google-services.json` 등은 `.gitignore`에 등록되어 있음.

---

## 3. 셋업

### 3.1 클론

```powershell
git clone https://github.com/SOMA-CleanName/gihagochi.git
cd gihagochi
```

### 3.2 pre-commit (권장, 한 번만)

커밋 시 ruff(Python) / dart format / trailing whitespace 자동 정리. CI에서 깨질 일 줄어듦.

```powershell
python -m pip install --user pre-commit
pre-commit install
```

### 3.3 백엔드

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1     # Windows
# source .venv/bin/activate      # Mac/Linux
pip install -e ".[dev]"

# .env 작성
Copy-Item .env.example .env
notepad .env                     # 메인 빌더에게 받은 값 채우기

# DB 마이그레이션 (dev Supabase에 적용)
alembic upgrade head
```

#### 흔한 함정
| 증상 | 해결 |
|---|---|
| `UnicodeDecodeError: 'cp949'` (alembic.ini) | alembic.ini는 ASCII only 유지 |
| `Multiple Connect call failed (127.0.0.1, 5432)` | DATABASE_URL이 Supabase가 아닌 로컬 가리킴. Session Pooler URL 사용 (`aws-X-region.pooler.supabase.com:5432`) |
| `pyiceberg` C 확장 빌드 실패 (Python 3.14) | `supabase<2.16` cap이 이미 pyproject에 들어가 있음 — `pip install -e ".[dev]"` 재실행 |

### 3.4 어드민

```powershell
cd admin
npm install
Copy-Item .env.example .env.local  # 없으면 메인 빌더에게 요청
notepad .env.local
```

### 3.5 모바일

```powershell
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

#### 흔한 함정 (모바일은 함정이 많음 — 차분히)

**a. Android Gradle 메모리 부족 (Windows 16GB RAM 환경)**

레포의 `mobile/android/gradle.properties`는 `-Xmx1536m`으로 튜닝되어 있음. 그래도 OOM 나면:
- Chrome 탭 닫기 (각각 200~400MB 점유)
- Docker Desktop 종료
- 안 되면 `-Xmx1024m`까지 추가로 낮춤
- 가용 RAM 5GB 이상 확보가 안전선

**b. Android 디바이스 인증**

```powershell
flutter devices
# Device R3CTxxxx is not authorized → 폰에서 USB 디버깅 다이얼로그 수락
```

**c. Firebase config 파일**

`mobile/android/app/google-services.json`이 없으면 FCM 비활성 (앱은 부팅됨, 푸시만 안 됨). 풀 기능 원하면 메인 빌더에게 요청.

**d. record / audioplayers 의존성**

현재 `pubspec.yaml`에서 주석 처리되어 있음. F-019/F-020(음성 메시지, P1) 작업 시작할 때 다시 활성. 활성 시 `record_linux` 호환성 확인 필요.

---

## 4. 첫 실행 검증

각 스택이 켜지는지만 확인 — 피처는 아직 없음.

### 4.1 백엔드

```powershell
cd backend
uvicorn app.main:app --reload
```

→ http://localhost:8000/health → `{"status":"ok"}`
→ http://localhost:8000/docs → Swagger UI

### 4.2 어드민

```powershell
cd admin
npm run dev
```

→ http://localhost:3000 → `/login`으로 리다이렉트 (인증 미들웨어 동작)

### 4.3 모바일 (선택)

dart-define으로 dev 환경에 연결 (백엔드는 로컬 또는 PROD):

```powershell
cd mobile
flutter run `
  --dart-define=SUPABASE_URL=https://<dev-ref>.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=eyJ... `
  --dart-define=API_BASE_URL=http://localhost:8000 `
  --dart-define=SENTRY_DSN=https://...@sentry.io/... `
  --dart-define=ENV=dev
```

> 실기기에서 `localhost`는 폰 자신을 가리킴. 같은 Wi-Fi의 PC를 가리키려면 PC의 LAN IP (`ipconfig`로 확인) 사용. 또는 `API_BASE_URL`을 Railway PROD로 임시 지정.

부팅 확인 포인트:
- `[main] Firebase init 실패` 경고 → 정상 (google-services.json 없으니까)
- `Env.assertRequired()` 통과 — SUPABASE_URL/ANON_KEY 필수
- 그 외 크래시 없으면 OK

---

## 5. 인프라 룰 (꼭 알아야 할 것)

### 5.1 직접 push 금지

`main` 브랜치는 보호됨. **모든 변경은 PR로**.

```powershell
git switch -c <type>/<설명>
# 예: feature/auth, fix/login-validation, docs/schema-update

# 작업 후
git push -u origin <브랜치명>
# GitHub 웹에서 PR 생성
```

CI(`ci.yml` / `guard.yml` / `migrations.yml`) 통과해야 머지 가능. 승인은 면제(0명).

### 5.2 메인 빌더 영역은 만지지 말 것

`AGENTS.md` 절대 룰 1번:
```
backend/app/core/, backend/app/shared/, backend/migrations/
mobile/lib/core/
admin/lib/, admin/middleware.ts
docs/, .github/
backend/pyproject.toml, mobile/pubspec.yaml, admin/package.json
```

수정 필요하면 PR 올리기 전에 메인 빌더에게 핑.

### 5.3 1 PR = 1 마이그레이션

CI가 `backend/migrations/versions/`에 추가된 파일 2개 이상이면 fail. 2개 필요하면 PR 나누기.

### 5.4 새 피처는 `_template` 복사로

```powershell
Copy-Item -Recurse backend/app/features/_template backend/app/features/<폴더>
Copy-Item -Recurse mobile/lib/features/_template mobile/lib/features/<폴더>
```

SPEC.md 먼저, 그 다음 구현. 자세히는 [`CONTRIBUTING.md`](./CONTRIBUTING.md).

### 5.5 AI 도구 사용 시

`AGENTS.md`가 룰 본체. Claude Code / Codex는 자동 로드. 다른 도구(Cursor, Copilot 등) 쓰면 세션 시작 시 수동으로 `AGENTS.md` 첨부.

---

## 6. 더 자세한 문서

| 문서 | 다룸 |
|---|---|
| [`AGENTS.md`](../AGENTS.md) | AI/사람 공용 절대 룰 (5개) |
| [`docs/CONTRIBUTING.md`](./CONTRIBUTING.md) | 피처 작업 라이프사이클 + PR 흐름 |
| [`docs/FEATURES.md`](./FEATURES.md) | 38개 피처 → 12개 작업 단위 매핑 |
| [`docs/SCHEMA.md`](./SCHEMA.md) | DB 테이블 + RLS 정책 |
| [`docs/ARCHITECTURE.md`](./ARCHITECTURE.md) | 시스템 구조, 호스팅, 핵심 결정 |
| [`backend/README.md`](../backend/README.md) | 백엔드 세부 셋업 + 배포 + 마이그레이션 |
| [`backend/AGENTS.md`](../backend/AGENTS.md) | 백엔드 stack-specific 룰 |
| [`mobile/README.md`](../mobile/README.md) | 모바일 세부 셋업 + Flutter 컨벤션 |
| [`mobile/AGENTS.md`](../mobile/AGENTS.md) | 모바일 stack-specific 룰 |
| [`admin/AGENTS.md`](../admin/AGENTS.md) | Next.js 16 breaking change 가이드 |

---

## 7. 막혔을 때

1. 이 문서 §3의 "흔한 함정" 표 먼저 확인
2. 해당 폴더의 `README.md` (backend/mobile에 자세한 troubleshooting 표 있음)
3. 그래도 안 풀리면 메인 빌더에게 핑 + 에러 메시지 전문 첨부

---

## 8. 환영 ✨

처음엔 함정 많지만 한 번 세팅 끝내면 피처 작업은 `_template` 복사 + SPEC.md + 코드. 단순함.

문제 풀리면 다음은 [`CONTRIBUTING.md`](./CONTRIBUTING.md) §2 — 작업 단위 받기.
