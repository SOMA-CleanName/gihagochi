# F-007 / F-028 / F-030 / F-032 / F-034 마이페이지 (profile) — 모바일

> 작업 단위 #9. backend SPEC 없음 (모바일 단독, Supabase 직결 + RLS).
> 진화하는 요구사항: [`../../../../feature-specs/profile.md`](../../../../feature-specs/profile.md)
>
> **F-024 (아이돌 메인) 제외** — chat 도메인 후속 재배치 (`docs/FEATURES.md` §10.4 이슈 #1).
> 폴더명: `profile`. `core/router/app_router.dart`에 `...profileRoutes` spread 1줄 추가 필요 (구현 시).
> `/` placeholder는 PR #33로 이미 `/main` redirect으로 전환 완료 — profile은 `/main`을 등록만 하면 됨.

---

## 개요

팬은 `/main`에서 응원 중 아이돌의 채팅방 리스트(shell)를 본다. 0명이면 빈 상태 + "아이돌 추가하기" CTA. 마이페이지(`/my`) 진입은 메인 우상단/하단 진입점. 아이돌은 F-024 머지 전까지 `/main` 진입 시 `/my`로 redirect하여 마이페이지를 임시 진입점으로 사용.

(`/` 진입 시 core router가 `/main`으로 redirect 처리 — PR #33.)

채팅 리스트 / 응원 중 / 알림 설정 3개 슬롯은 **Provider override 패턴**으로 비워둠 — chat_room, subscription, notification이 머지 시 본 SPEC의 공개 Provider를 override해서 끼움.

관련 화면 / 사용자 / 우선순위: `docs/FEATURES.md` §3.4 (F-007 / F-028 / F-030 / F-032 / F-034).

---

## 화면 (Routes)

| Route | 화면 | 진입 조건 |
|---|---|---|
| `/main` | MainScreen — 팬 메인 (채팅방 리스트 shell) | 로그인 + role=fan (role=idol은 `/my`로 redirect) |
| `/my` | 마이페이지 (역할별 분기) | 로그인 |
| `/my/edit/fan` | 팬 프로필 편집 (display_name, avatar_url) | role=fan |
| `/my/edit/idol` | 아이돌 프로필 편집 (display_name, avatar_url + stage_name, bio, thumbnail_url) | role=idol |
| `/my/account` | 계정·보안 (회원 탈퇴) | 로그인 |
| `/my/legal/tos` | 이용약관 (placeholder 텍스트, 출시 전 교체) | 공개 |
| `/my/legal/privacy` | 개인정보 처리방침 (placeholder 텍스트, 출시 전 교체) | 공개 |
| `/my/legal/contact` | 고객센터 (mailto: 안내) | 공개 |

post-login redirect 흐름:
- core router (PR #33): `/` → `/main` redirect
- auth_guard: 로그인 사용자를 `/main`으로 redirect (PR #33)
- `/main` 진입 시 MainScreen이 `profiles.role` 확인 → idol이면 즉시 `/my`로 redirect
- 가입 직후 흐름은 auth가 `/discover`로 보냄 (idol_discovery 머지 전엔 그 라우트 미존재 → 추후 정착)

---

## 의존 화면 / 데이터

- **화면 진입 경로**: auth_guard가 로그인 사용자를 `/main`으로 redirect → MainScreen → 마이페이지는 우상단/하단 진입점 탭
- **읽기 (Supabase 직결, RLS 보호)**:
  - `profiles` (자기 row) — role, status, display_name, avatar_url, deleted_at
  - `idol_profiles` (자기 row, role=idol일 때) — stage_name, bio, thumbnail_url
  - `idol_signup_applications` (자기 최신 row, role=idol & status=pending일 때) — 거절 사유 표시용 (auth에서 이미 fetch 중이면 그 캐시 재사용)
- **쓰기 (Supabase 직결)**:
  - `profiles` UPDATE — display_name, avatar_url, deleted_at
  - `idol_profiles` UPDATE — stage_name, bio, thumbnail_url
- **Storage (Supabase 직결)** — dev 환경에 적용 완료. 패턴은 **private + signed URL** (구현 시 public 전환 재검토 가능):
  - `avatars` 버킷 — path `<user_id>/avatar.jpg` (overwrite). 5MB / JPEG·PNG / private. UI는 `?v=<updated_at_ms>`로 cache bust
  - `idol-thumbnails` 버킷 — path `<user_id>/thumbnail.jpg` (overwrite). 5MB / JPEG·PNG / private. role=idol AND status=active만 INSERT/UPDATE 허용 (RLS)
  - SELECT은 authenticated 누구나 (signed URL 발급 위해)
- **백엔드 API**: 없음 (전부 Supabase 직결)
- **Realtime 구독**: 없음

> **알렘빅 migration TODO**: 위 RLS 정책 + 버킷 설정은 dev DB에 SQL 직접 적용된 상태. staging/prod 재현용 알렘빅 migration은 별도 `infra/storage-rls` PR로 캡처 예정 ([feature-specs/profile.md](../../../../feature-specs/profile.md) "후속 작업" 참조).

---

## 의존 (core)

- `core.auth.auth_service.supabaseProvider` — Supabase 직결 (RLS 의존)
- `core.router.app_router` — `...profileRoutes` spread 1줄 추가 (`/` redirect / auth_guard 타겟은 PR #33에서 이미 `/main`)
- features/auth 공개 인터페이스: `getCurrentProfile()`, `isActiveIdol()`, `signOut()` 호출
- `core.widgets.avatar.Avatar` — 기존 아바타 위젯 (URL 없으면 이니셜 fallback)

> **메인 빌더 영역 변경 후속 TODO** (본 PR 범위 외, 별도 작업으로):
> 1. ~~`core/router/app_router.dart` placeholder 정리~~ — PR #33로 완료
> 2. ~~Supabase Storage 버킷 + RLS~~ — dev 적용 완료 (staging/prod 재현용 알렘빅 migration `infra/storage-rls`로 분리 예정)
> 3. 약관/개인정보 본문 — placeholder 텍스트로 본 PR 진행. 출시 전 메인 빌더가 실제 문안으로 교체 (`mobile/pubspec.yaml` assets 갱신 없이 hardcoded String으로 시작)

---

## 비즈니스 룰

- 마이페이지는 `profiles.role` 기반 분기:
  - **fan** → 프로필 카드 / 응원 중 아이돌 슬롯 (subscription override) / 알림 설정 슬롯 (notification override) / 계정·보안 / 약관·정책·고객센터 / 로그아웃
  - **idol** → 프로필 카드 / "메시지 발행 준비 중" 배너 / 알림 설정 슬롯 / 계정·보안 / 약관·정책·고객센터 / 로그아웃 (응원 중 섹션 숨김)
- avatar / thumbnail 업로드: **5MB 이하, JPEG/PNG만, 클라 리사이즈** (avatar 512x512, thumbnail 1024x1024). 위반 시 토스트 + 업로드 중단
- 업로드 흐름: 클라 리사이즈 → Supabase Storage upload → UPDATE profiles/idol_profiles의 URL 컬럼 → 캐시 무효화 (cache bust 쿼리스트링)
- 아이돌 프로필 편집은 **즉시 반영** (관리자 승인 없음). stage_name unique 제약 위반 시 토스트 ("이미 사용 중인 활동명")
- 회원 탈퇴: 확정 모달 → `profiles.deleted_at = NOW()` UPDATE → features/auth의 `signOut()` 호출 → auth router가 `/auth/landing`으로 redirect
- 비밀번호 변경 UI 없음 (Google OAuth only). 계정 섹션에 "Google 계정에서 관리" 안내 텍스트
- 약관 / 개인정보 / 고객센터는 화면별 hardcoded placeholder 텍스트 (assets/pubspec.yaml 변경 없음). 출시 전 메인 빌더가 실제 문안으로 교체
- 채팅방 리스트 / 응원 중 / 알림 설정 슬롯은 **Provider override 패턴**으로 비워둠. default = 빈 상태 위젯. 다른 피처가 override 시 자동 교체

---

## 엣지 케이스

- **응원 중 아이돌 0명** → MainScreen 빈 상태 + "아이돌 추가하기" CTA → `/discover` 이동 (idol_discovery 머지 전엔 미존재 경로 → 토스트 fallback)
- **아이돌이 `/main` 진입** → MainScreen이 즉시 `/my`로 redirect (F-024 머지 시 본 redirect 제거 예정)
- **avatar / thumbnail 업로드 실패** → 기존 URL 유지, 토스트로 에러 표시 + Sentry 보고
- **avatar URL stale** (직전 업로드 후 캐시) → URL에 `?v=<profiles.updated_at_ms>` 쿼리스트링 붙여 cache bust
- **stage_name unique violation** → DB가 23505 throw → 토스트 "이미 사용 중인 활동명입니다"
- **회원 탈퇴 후 같은 Google 계정 재로그인** → 차단은 auth 책임 (auth가 `profiles.deleted_at != null` 시 가입 거부 또는 복구 모달). 본 PR은 표시만
- **idol_signup_applications.status='rejected'** + 본인 마이페이지 진입 → 상단에 거절 사유 + "재신청" 진입점 (단 재신청 UI 본체는 auth, 본 PR은 텍스트 + auth 라우트로 링크만)
- **비로그인 진입** → auth_guard가 `/auth/landing`으로 redirect (이미 처리)
- **약관 페이지 외부 링크 X** → hardcoded placeholder만, 오프라인 OK
- **storage RLS 거부** (예: 잘못된 path) → supabase가 403 → 토스트 "이미지 업로드 실패. 운영자에게 문의" + Sentry

---

## 공개 인터페이스 (다른 피처가 호출 가능)

```dart
// features/profile/data/profile_repository.dart
//
// 자기 프로필 조회 (캐시 가능). auth의 getCurrentProfile()와 중복되어 보이지만,
// 본 함수는 profile 도메인 모델(MyProfile)을 반환 — avatar URL + idol 확장 필드 포함.
Future<MyProfile> fetchMyProfile();

// features/profile/application/slots.dart
//
// MainScreen 채팅방 리스트 슬롯. chat_room이 머지 시 override.
// default = "응원 중 아이돌이 없어요" 빈 상태 + CTA 위젯.
final chatListSlotProvider = Provider<Widget>((_) => const EmptyChatListSlot());

// 마이페이지 응원 중 슬롯. subscription이 머지 시 override.
// default = "응원 기능 준비 중" 회색 카드.
final subscriptionListSlotProvider = Provider<Widget>((_) => const PlaceholderSubscriptionSlot());

// 마이페이지 알림 설정 슬롯. notification이 머지 시 override.
// default = "알림 설정 준비 중" 회색 카드.
final notificationSettingsSlotProvider = Provider<Widget>((_) => const PlaceholderNotificationSlot());
```

> 위 3개 Provider를 다른 피처가 `ProviderScope.overrides` 또는 자체 routes에서 override해서 끼움. profile은 chat_room / subscription / notification을 모름 (의존 역방향 OK).
> 위에 없는 메서드/위젯은 internal.

---

## 수동 테스트 시나리오 (PR 첨부)

### 시나리오 1: 팬 메인 빈 상태
1. 팬으로 가입 완료 → 앱 cold start → `/` 진입 → `/main` redirect
2. "응원 중인 아이돌이 없어요" 빈 상태 + "아이돌 추가하기" CTA 표시 확인
3. CTA 탭 → `/discover` 이동 (idol_discovery 미머지면 토스트 fallback 확인)

### 시나리오 2: 팬 프로필 편집
1. `/main` → 마이페이지 진입 → 프로필 카드 + 4개 섹션 표시 확인
2. "프로필 편집" 탭 → display_name 변경 + avatar 업로드
3. 저장 → 마이페이지 복귀 시 이름/이미지 반영 확인
4. 잘못된 포맷 (예: 6MB BMP) 업로드 시도 → 토스트 표시 + 업로드 차단

### 시나리오 3: 아이돌 임시 진입점
1. 아이돌로 가입 + 승인 완료 (관리자 admin 머지 전엔 DB 직접 UPDATE)
2. `/main` 진입 → 즉시 `/my`로 redirect 확인
3. 마이페이지 상단 "메시지 발행 준비 중" 배너 표시
4. "아이돌 프로필 편집" 진입 → stage_name + bio + thumbnail 변경 → 저장
5. stage_name을 다른 아이돌과 동일하게 시도 → 토스트 "이미 사용 중"

### 시나리오 4: 회원 탈퇴
1. 마이페이지 → 계정·보안 → "회원 탈퇴" 탭
2. 모달 "정말 탈퇴하시겠습니까? 30일 내 재로그인 시 복구됩니다" → 확인
3. `/auth/landing` 자동 이동
4. DB 확인: `profiles.deleted_at` NOT NULL
5. 같은 Google 계정 재로그인 시도 → 차단 (auth 책임, 본 PR 범위 외)

### 시나리오 5: 약관 / 로그아웃
1. 마이페이지 → 이용약관 → placeholder 텍스트 페이지 표시 (오프라인에서도 OK)
2. 개인정보 처리방침 / 고객센터(mailto:) 동일 확인
3. 로그아웃 탭 → `/auth/landing` 이동 + 앱 재시작 후 `/auth/landing` 유지

### 시나리오 6: 슬롯 default 동작
1. chat_room / subscription / notification 미머지 상태에서 MainScreen / 마이페이지 진입
2. 채팅 리스트 영역, 응원 중 영역, 알림 설정 영역 모두 default 빈 상태 위젯 표시 확인
