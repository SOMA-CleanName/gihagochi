# F-001~F-006 인증/계정 (auth) — 모바일

> 작업 단위 #1. backend SPEC: [`../../../../backend/app/features/auth/SPEC.md`](../../../../backend/app/features/auth/SPEC.md)
> 진화하는 요구사항: [`../../../../feature-specs/auth.md`](../../../../feature-specs/auth.md)
>
> 폴더명: `auth`. `core/router/app_router.dart`에 `authRoutes` 1줄 import 필요 (구현 시).

---

## 개요

옵션 C: 가입 화면에서 "팬으로 가입" vs "아이돌로 가입" 선택. 약관 체크박스 통과 후 **Google로 시작** 버튼 1개. Supabase native OAuth → `supabase.auth.signInWithOAuth({ provider: 'google' })` 호출로 처리 (mobile native SDK 추가 X). OAuth 콜백 후 backend `POST /auth/signup` 호출로 프로필 + (선택)아이돌 신청 + 약관 동의를 트랜잭션 생성. 로그인은 Google 계정 재선택 → `GET /auth/me`로 프로필 조회 후 사용자 타입에 따라 진입 화면 분기.

> Apple/Kakao/Naver는 1차 출시 제외. 차후 Kakao 등 추가 시 Apple Sign in with Apple 동시 추가 필요 (App Store 가이드라인 4.8).

관련 화면 / 사용자 / 우선순위: `docs/FEATURES.md` §3.1 (F-001~F-006).

---

## 화면 (Routes)

| Route | 화면 | 진입 조건 |
|---|---|---|
| `/auth/landing` | 가입/로그인 진입 ("Google로 시작" 버튼 + 가입/로그인 토글) | 비로그인 상태 |
| `/auth/signup/role` | 가입 타입 선택 ("팬으로 가입" / "아이돌로 가입") | landing에서 "가입" 선택 후 |
| `/auth/signup/terms` | 약관 동의 체크박스 (tos/privacy 필수, marketing 선택) | 가입 타입 선택 후 |
| `/auth/signup/profile` | display_name 입력 (+ 아이돌이면 stage_name, bio) | 약관 동의 + OAuth 콜백 후 |
| `/auth/idol-pending` | 아이돌 승인 대기 화면 (신청일 + 거절 시 사유 + 재신청 버튼) | role=fan + idol_signup_applications.status=pending\|rejected |

로그인 진입 시:
- 프로필 없음 → `/auth/signup/profile` (가입 미완료 복구)
- profile 있음 + 아이돌 활성 → `/idol/home` (다른 피처)
- profile 있음 + 아이돌 대기 → `/auth/idol-pending`
- profile 있음 + 일반 → `/discover` (아이돌 탐색)

---

## 의존 화면 / 데이터

- **화면 진입 경로**: 앱 cold start 시 `auth_service`가 Supabase 세션 확인 → 없으면 `/auth/landing`, 있으면 `GET /auth/me`로 분기
- **읽기**: 백엔드 API — `GET /auth/me`, `GET /auth/terms/current`
- **쓰기**: 백엔드 API — `POST /auth/signup`, `POST /auth/logout`
- **Realtime 구독**: 없음
- **Supabase 직결**:
  - `supabase.auth.signInWithOAuth(OAuthProvider.google, redirectTo: oauthRedirectUrl)` — redirectTo 없으면 콜백 못 돌아옴
  - `supabase.auth.signOut()` — 로그아웃 시 함께 호출

### OAuth deep link 흐름

`oauthRedirectUrl = 'com.gihagochi.gihagochi://login-callback'` ([core/auth/auth_service.dart](../../../core/auth/auth_service.dart) 정의)

1. 앱: `signInWithOAuth(provider, redirectTo: oauthRedirectUrl)` 호출
2. Supabase Auth가 시스템 브라우저(Chrome 등)로 Google 동의 화면 열기
3. 사용자 동의 → Google이 `https://<project-ref>.supabase.co/auth/v1/callback?code=...`로 redirect
4. Supabase가 code↔token 교환 → `oauthRedirectUrl`로 추가 redirect
5. Android가 scheme `com.gihagochi.gihagochi`의 intent-filter 매칭 → 앱 활성화 (MainActivity onNewIntent)
6. supabase_flutter SDK가 URL 파싱 → 세션 저장 → `onAuthStateChange` SIGNED_IN 발화
7. 라우터 refresh 리스너가 `/auth/me` 조회 후 적절한 화면으로 redirect

> MainActivity `launchMode="singleTask"` 필수. singleTop이면 Chrome이 deep link를 새 task로 보낼 때 cold restart가 일어나 deep link URL이 손실됨.

---

## 의존 (core)

- `core.api.dio_client.dio` — 백엔드 API 호출 (`/auth/*`)
- `core.auth.auth_service.supabaseProvider` — Supabase 세션/OAuth
- `core.router.app_router` — route 등록 (1줄 import 추가만, 본체 수정 X)
- `core.widgets.*` — 공용 위젯 (버튼/체크박스/입력 폼)

> Google은 Supabase native OAuth라 `pubspec.yaml` 변경 불필요 (인지 트리거 #2 해소).
>
> 메인 빌더 추가 작업 (Supabase Studio 측):
> - Authentication → Providers에서 Google 활성 + client_id/secret 입력
> - Google Cloud Console → APIs & Services → Credentials에서 OAuth 2.0 Client ID (Web) 발급
> - Authorized redirect URI: `https://<project-ref>.supabase.co/auth/v1/callback`
> - Supabase Dashboard → Authentication → URL Configuration → Redirect URLs에 `com.gihagochi.gihagochi://login-callback` 등록 (없으면 deep link 차단됨)

---

## 비즈니스 룰

- 가입 진입 → 가입 타입 선택 → 약관 동의 → 소셜 제공자 선택 → OAuth → display_name(+stage_name) 입력 → `POST /auth/signup` 1회 호출.
- OAuth 완료 후 `POST /auth/signup`이 실패하면 (네트워크 등) 다음 cold start 시 `GET /auth/me`가 404를 반환 → 가입 미완료 화면으로 복귀해서 재시도.
- `POST /auth/signup` 409 (이미 가입됨)는 클라이언트가 "로그인 성공"으로 해석하고 `GET /auth/me`로 fallback.
- 로그아웃: `POST /auth/logout` + `supabase.auth.signOut()` 동시 호출. 둘 다 실패해도 로컬 세션은 강제 클리어.
- 자동 로그인: Supabase가 refresh 자동 처리. refresh 만료 시 401 → 인터셉터가 세션 클리어 + `/auth/landing` 강제 이동.
- 아이돌 신청자는 `/discover` 등 팬 기능은 사용 가능. 아이돌 발행 화면(`/idol/*`)만 접근 차단 (라우터 가드).
- 약관 동의 화면은 가입 시 1회만. 약관 version 변경 시 재동의 정책은 본 PR 범위 외 (차후 결정).

---

## 엣지 케이스

- 이미 다른 소셜로 가입된 이메일로 새 제공자 가입 시도 → Supabase는 별도 user로 생성. `POST /auth/signup`은 정상 진행. (정책 재검토는 차후)
- OAuth 도중 사용자 취소/뒤로가기 → 가입 화면으로 복귀, 토스트 표시.
- OAuth provider 자체 오류 (Supabase Dashboard 미설정, 잘못된 client_id 등) → 해당 버튼은 표시되지만 OAuth 호출 시 supabase_flutter가 에러 throw → 에러 메시지 표시 + Sentry 보고.
- 약관 version mismatch (서버가 v2인데 클라가 v1 캐시) → 400 응답 → 동의 화면으로 강제 복귀, 새 version 재표시.
- 아이돌 신청 후 재로그인 → `/auth/idol-pending` 진입. 단 `idol_signup_applications` 가장 최신 row의 status로 판단:
  - pending → "심사 중" 메시지
  - rejected → 사유 표시 + "재신청" 버튼
  - approved → `/idol/home`으로 이동 (다음 cold start까지 stale이면 강제 redirect)
- 아이돌 가입자가 신청 안 한 채 앱 종료 (display_name까지만 입력) → 다음 진입 시 `GET /auth/me` 결과로 복구 (profile 있고 idol app 없음 → 그냥 팬 상태로 진행 + 마이페이지에서 별도 "아이돌 신청" 진입은 본 PR 범위 외)

---

## 공개 인터페이스 (다른 피처가 호출 가능)

```dart
// repository.dart / controller의 public 메서드만.
// 여기 없는 함수는 다른 피처가 호출하지 말 것.

// 현재 사용자의 프로필 요약 (role/status/display_name).
// 다른 피처가 표시용으로 사용.
Future<ProfileSummary?> getCurrentProfile();

// 현재 사용자가 아이돌인지 (role=idol AND status=active).
// 라우터 가드 / 화면 조건 분기용.
bool isActiveIdol();

// 강제 로그아웃 (401 인터셉터 등에서 호출).
Future<void> forceSignOut();
```

> 위에 없는 메서드는 internal.

---

## 수동 테스트 시나리오 (PR 첨부)

### 시나리오 1: 팬 가입 (Google)
1. 앱 첫 진입 → `/auth/landing` → "가입" → "팬으로 가입"
2. tos/privacy 체크 → "Google로 시작" 탭
3. Google OAuth 완료 → display_name 입력 → "완료"
4. `/discover` 진입 확인

### 시나리오 2: 아이돌 가입 (Google) + 승인 대기
1. `/auth/landing` → "가입" → "아이돌로 가입"
2. tos/privacy 체크 → "Google로 시작"
3. Google OAuth 완료 → display_name + stage_name + bio 입력 → "완료"
4. `/auth/idol-pending` 진입 → 신청일 표시 확인
5. 백엔드에서 강제로 `idol_signup_applications.status='rejected', rejection_reason='샘플 사유'` UPDATE
6. 앱 재시작 → `/auth/idol-pending` 거절 사유 표시 + "재신청" 버튼 확인

### 시나리오 4: 로그아웃 + 자동 로그인 차단
1. 로그인 상태 → 마이페이지 → 로그아웃 탭
2. 앱 재시작 → `/auth/landing` 표시 (자동 로그인 X)

### 시나리오 5: 토큰 만료 처리
1. 로그인 상태에서 Supabase Studio에서 refresh token 강제 만료
2. 앱에서 백엔드 호출 → 401
3. 인터셉터가 세션 클리어 + `/auth/landing` 강제 이동
