# F-001~F-006 인증/계정 (auth)

> 작업 단위 #1 — 모든 피처의 기반. 레퍼런스 피처.
> 진화하는 요구사항은 [`feature-specs/auth.md`](../../../../feature-specs/auth.md).

---

## 개요

팬/아이돌이 소셜 로그인(Google/Apple/Kakao/Naver)으로 가입·로그인하고, 옵션 C(가입 화면에서 팬/아이돌 선택) 흐름으로 사용자 타입을 분기한다. 아이돌은 가입 시 `idol_signup_applications`에 신청 row가 함께 생성되고, 관리자 승인 후 활성화된다. Supabase Auth + RLS를 기반으로 한다.

관련 화면 / 사용자: `docs/FEATURES.md` §3.1 (F-001~F-006).

---

## API

| Method | Path | 설명 | 인증 |
|---|---|---|---|
| POST | `/auth/signup` | 소셜 로그인 후 프로필 + (선택)아이돌 신청 + 약관 동의를 한 번에 생성 | `PendingAuthUser` (Supabase JWT만 검증, profile 없어도 OK — 별도 PR로 core.auth에 추가됨) |
| GET  | `/auth/me` | 현재 사용자의 profiles + (있으면) idol_signup_applications 최신 상태 | AuthedUser |
| POST | `/auth/logout` | 서버측 토큰 무효화 트리거 (Supabase 세션 종료. 클라이언트가 호출) | AuthedUser |
| GET  | `/auth/terms/current` | 현재 활성 약관 version 목록 (tos / privacy / marketing) | 비인증 OK |

### POST /auth/signup — 요청 본문

```jsonc
{
  "as": "fan" | "idol",           // 가입 타입 선택 (옵션 C)
  "display_name": "string",       // 필수, 1~30자
  "stage_name": "string?",        // as=idol 일 때 필수
  "bio": "string?",               // as=idol 일 때 선택
  "application_note": "string?",  // as=idol 일 때 선택 (자기소개/심사용)
  "agreements": {
    "tos": {"version": "v1"},
    "privacy": {"version": "v1"},
    "marketing": {"version": "v1", "agreed": false}  // 선택
  }
}
```

응답: `200` + 생성된 profile 요약. 이미 profiles 있으면 `409 conflict`.

### POST /auth/signup — 처리 흐름 (단일 트랜잭션)

1. `auth.uid()`로 신규 user 확인. 동일 user_id로 profiles 이미 있으면 409.
2. `profiles` INSERT: `role='fan'`, `status='active'`, `display_name`.
3. `as='idol'`이면: `idol_signup_applications` INSERT: `status='pending'`, `stage_name`, `bio`, `application_note`.
4. `terms_agreements` INSERT × N: tos/privacy 필수, marketing은 `agreed=true`일 때만.
5. 커밋 → 응답.

---

## DB

- **읽기**: `profiles`, `idol_signup_applications` (자기 것만)
- **쓰기**: `profiles` (자기 row만 INSERT), `idol_signup_applications` (자기 신청 INSERT), `terms_agreements` (자기 동의 INSERT)
- **새 컬럼/테이블 필요**: 없음. `0001_initial`의 스키마 그대로 사용.

스키마 인용 (`0001_initial.py` 참조):
- `profiles(id ⊂ auth.users, role user_role, status user_status, display_name, avatar_url, ...)`
- `idol_signup_applications(id, user_id ⊂ profiles, stage_name, bio, status signup_application_status, ...)`
- `terms_agreements(id, user_id ⊂ profiles, type agreement_type, version, agreed_at)`

ENUM:
- `user_role`: `'fan' | 'idol' | 'admin'`
- `user_status`: `'pending' | 'active' | 'suspended'`
- `signup_application_status`: `'pending' | 'approved' | 'rejected' | 'withdrawn'`
- `agreement_type`: `'tos' | 'privacy' | 'marketing'`

---

## 의존 (호출하는 core / 다른 피처)

- `core.auth.get_current_user` / `require_role(...)` — 현재 사용자 추출 (Supabase JWT 검증)
- `core.db.get_session` — AsyncSession 의존성 주입
- (없음) 다른 피처 호출 안 함. auth는 레퍼런스 피처라 호출당하기만 함.

---

## 비즈니스 룰

- 가입은 1회만 — 동일 `auth.users.id`로 두 번째 `POST /auth/signup` 시 409.
- 일반(팬) 가입: `profiles.role='fan'`, `status='active'`. 즉시 모든 팬 기능 사용 가능.
- 아이돌 가입: profile은 fan/active로 활성. 별도로 `idol_signup_applications` pending row 생성. 승인 전엔 팬 기능만 사용 가능, 아이돌 기능(메시지 발행 등)은 잠금.
- 아이돌 승인 처리 자체는 본 피처 책임 X — `features/admin` 작업 단위에서 처리. 본 피처는 신청 row INSERT까지만.
- 거절된 신청자는 재신청 가능 — 새 row INSERT. 이전 row는 `rejected` 상태로 history 보존.
- 로그아웃은 Supabase 기본 동작 (refresh token 무효화). 백엔드는 별도 블랙리스트 미관리.
- 약관 동의: tos/privacy 미제출 또는 `agreed=false`면 400. marketing은 선택.
- 약관 version은 `agreements.<type>.version` 문자열을 그대로 신뢰. 검증은 `/auth/terms/current` 응답과 일치하는지 확인 (mismatch 시 400, 클라이언트에 재요청 유도).

---

## 엣지 케이스

- 신규 가입 직후 네트워크 끊김 → 클라이언트가 재시도. 동일 user_id 두 번째 시도는 409 — 클라이언트는 409를 "이미 가입 완료"로 해석하고 `GET /auth/me`로 fallback.
- `as='idol'` + `stage_name` 누락 → 400.
- `stage_name` 중복 (`idol_profiles.stage_name UNIQUE` 제약) → 신청 단계에선 idol_profiles에 INSERT 안 하므로 충돌 없음. 단, 승인 시점에 중복이면 admin 단계에서 거절 사유로 처리.
- 약관 version mismatch (클라이언트가 오래된 version 보냄) → 400, 클라이언트 재요청.
- 가입 트랜잭션 중 1개라도 실패 → 전체 롤백.
- 로그아웃 호출 시 이미 만료된 토큰 → 401. 클라이언트는 어차피 로그인 화면으로 이동하므로 무시 OK.

---

## 공개 인터페이스 (다른 피처가 호출 가능)

```python
# service.py에서 export하는 public 함수.
# 여기 없는 함수는 다른 피처가 호출하지 말 것.

from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession

async def get_profile_summary(
    session: AsyncSession, user_id: UUID
) -> ProfileSummary | None:
    """user_id → 기본 프로필 (role/status/display_name). 다른 피처가 표시용으로 사용."""

async def has_pending_idol_application(
    session: AsyncSession, user_id: UUID
) -> bool:
    """아이돌 신청 pending 여부. features/admin이 승인 처리 시 / UI에서 표시용."""
```

> 위에 명시 안 된 함수는 internal. 다른 피처가 import 금지.
> `get_current_user` / `require_role` 같은 인증 의존성은 `core.auth`에 있음 (이 피처가 노출 X).

---

## 수동 테스트 시나리오 (PR에 첨부)

### 시나리오 1: 팬 가입 골든 패스
1. 앱 첫 진입 → 가입 화면 → "팬으로 가입" 선택
2. tos + privacy 체크 (marketing 미체크) → Google 버튼 탭
3. Google OAuth 완료 후 디스플레이 이름 입력 → 확인
4. `POST /auth/signup` 호출 (as=fan)
5. 메인 화면(아이돌 탐색) 진입

기대 결과:
- `profiles` 새 row (role=fan, status=active, display_name 일치)
- `terms_agreements` 2개 row (tos, privacy)
- 401/500 없이 200 응답

### 시나리오 2: 아이돌 가입 + 승인 대기
1. "아이돌로 가입" 선택 → tos + privacy 체크 → Apple 버튼 탭
2. Apple OAuth 완료 후 display_name, stage_name, bio 입력
3. `POST /auth/signup` 호출 (as=idol)
4. "승인 대기 중" 화면 진입 (신청일 표시)

기대 결과:
- `profiles` 새 row (role=fan, status=active)
- `idol_signup_applications` 새 row (status=pending, stage_name 일치)
- `terms_agreements` 2개 row
- 팬 기능(아이돌 탐색 등)은 사용 가능. 아이돌 발행 화면은 잠금 (또는 미노출)

### 시나리오 3: 중복 가입 시도
1. 시나리오 1 완료 후 같은 Google 계정으로 재로그인 (앱 재설치 후 등)
2. `POST /auth/signup` 호출

기대 결과:
- 409 응답
- 클라이언트가 `GET /auth/me`로 fallback → 정상 로그인 처리

### 시나리오 4: 로그아웃 + 자동 로그인 차단
1. 로그인 상태에서 마이페이지 → 로그아웃
2. 앱 재시작

기대 결과:
- 로그아웃 시 `POST /auth/logout` 호출
- 재시작 시 로그인 화면 (이전 세션 자동 복구 X)
