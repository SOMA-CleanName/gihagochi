# F-035 / F-036 / F-038 관리자 (admin)

> 작업 단위 #11 — 관리자 웹 전용 슬라이스.
> 진화하는 요구사항은 [`feature-specs/admin.md`](../../../../feature-specs/admin.md).
> 어드민 웹 페이지(`admin/app/(admin)/signups`, `.../users`)는 별도 SPEC.md 두지 않고 본 파일이 단일 진실의 원천.

---

## 개요

관리자가 어드민 웹에서 (1) 아이돌 가입 신청 큐를 처리(승인/반려), (2) 사용자·아이돌 리스트를 조회·필터·검색, (3) 사용자 정지/해제로 운영한다. **mutation은 백엔드 API 트랜잭션**, **SELECT는 어드민 웹 Server Component가 supabase server client + admin RLS**로 직접 처리하는 혼합 패턴.

관련 화면 / 사용자 / 우선순위: `docs/FEATURES.md` §3.7 (F-035 / F-036 / F-038).

---

## API

| Method | Path | 설명 | 인증 |
|---|---|---|---|
| POST | `/admin/idol-applications/{id}/approve` | 아이돌 가입 신청 승인 (트랜잭션) | `AdminUser` |
| POST | `/admin/idol-applications/{id}/reject` | 아이돌 가입 신청 반려 (rejection_reason 필수) | `AdminUser` |
| POST | `/admin/users/{id}/suspend` | 사용자 정지 (suspend_reason 필수) | `AdminUser` |
| POST | `/admin/users/{id}/unsuspend` | 사용자 정지 해제 | `AdminUser` |

> SELECT (신청 큐 / 사용자 리스트 / 필터 / 검색)는 백엔드 API 미노출. 어드민 웹 Server Component가 `lib/supabase/server`로 직접 호출.
> 이유: 관리자 RLS 정책이 이미 `SCHEMA.md` §5에 정의되어 있어 admin role JWT만 있으면 SELECT 통과. SSR 친화.

### POST /admin/idol-applications/{id}/approve

요청 본문: 없음
응답: `200` + 승인된 신청 요약

처리 흐름 (단일 트랜잭션):
1. `idol_signup_applications` 조회 — `id`로 1건. 없으면 404.
2. `status='pending'` 아니면 409 "이미 처리됨".
3. `UPDATE idol_signup_applications SET status='approved', handled_by=auth.uid(), handled_at=NOW() WHERE id=? AND status='pending'` — 영향 row 0이면 409 (동시 처리 충돌).
4. `INSERT idol_profiles (id=user_id, signup_application_id, stage_name, bio, ...)` — `stage_name` UNIQUE 충돌 시 IntegrityError → 트랜잭션 롤백 + 409 "활동명 중복".
5. `UPDATE profiles SET role='idol' WHERE id=user_id`.
6. 커밋 → 응답.

### POST /admin/idol-applications/{id}/reject

요청 본문:
```jsonc
{
  "rejection_reason": "string"   // 필수, 1~500자
}
```

처리 흐름:
1. 신청 조회 — 없으면 404.
2. `status='pending'` 아니면 409.
3. `UPDATE ... SET status='rejected', rejection_reason=?, handled_by=auth.uid(), handled_at=NOW() WHERE id=? AND status='pending'`.
4. 커밋 → 응답.

### POST /admin/users/{id}/suspend

요청 본문:
```jsonc
{
  "suspend_reason": "string"   // 필수, 1~500자
}
```

처리 흐름:
1. `id == auth.uid()` 이면 400 "자기 자신은 정지 불가".
2. `profiles` 조회 — 없으면 404.
3. `status='suspended'` 이미면 400 "이미 정지됨".
4. `UPDATE profiles SET status='suspended', suspended_at=NOW(), suspend_reason=? WHERE id=?`.
5. 커밋 → 응답.

### POST /admin/users/{id}/unsuspend

요청 본문: 없음

처리 흐름:
1. `profiles` 조회 — 없으면 404.
2. `status='suspended'` 아니면 400 "정지 상태가 아님".
3. `UPDATE profiles SET status='active', suspended_at=NULL, suspend_reason=NULL WHERE id=?`.
4. 커밋 → 응답.

---

## DB

- **읽기 (어드민 웹 Server Component 경유)**: `profiles`, `idol_signup_applications`, `idol_profiles`
- **쓰기 (백엔드 API 경유)**:
  - `idol_signup_applications`: UPDATE (status, handled_by, handled_at, rejection_reason) only
  - `idol_profiles`: INSERT only (승인 시 1회)
  - `profiles`: UPDATE (role / status / suspended_at / suspend_reason) only
- **새 컬럼/테이블 / RLS 마이그레이션**: 없음. 0001_initial 스키마 + 기존 RLS 정책 그대로 사용.

### `idol_signup_applications` 슬라이스 contract (auth ↔ admin)

| 슬라이스 | INSERT | UPDATE | DELETE |
|---|---|---|---|
| `auth` | ✅ status='pending', user_id, stage_name, bio, application_note | ❌ | ❌ |
| `admin` | ❌ | ✅ status, handled_by, handled_at, rejection_reason | ❌ |

withdrawn 처리는 auth 슬라이스의 신청자 본인 액션 (현재 UI 미구현, 차후).

---

## 의존 (호출하는 core / 다른 피처)

- `core.auth.AdminUser` — role=admin 의무 의존성 (status=active 자동 검증)
- `core.db.get_session` — AsyncSession 주입
- `core.errors.NotFoundError` / `ConflictError` / `ValidationError`
- `app.shared.models.Profile`, `IdolProfile`, `IdolSignupApplication`
- `app.shared.enums.UserRole`, `UserStatus`, `SignupApplicationStatus`
- **다른 피처 호출 없음** (admin은 leaf — 다른 슬라이스가 호출하지 않음)

---

## 비즈니스 룰

- 모든 mutation은 `AdminUser` 의존성 통과 = role=admin + status=active 사용자만.
- 신청 승인/반려는 `status='pending'` 조건의 conditional UPDATE — 동시 처리 충돌은 409로 명시.
- 신청 승인은 3-step 트랜잭션 (applications UPDATE + idol_profiles INSERT + profiles UPDATE). 하나라도 실패하면 전체 롤백.
- `idol_profiles.stage_name` UNIQUE 충돌 = 409. 어드민이 신청자에게 다른 활동명을 안내하고 거절 후 재신청 유도.
- 거절은 `rejection_reason` 필수. 재신청은 새 row INSERT (auth 슬라이스). 본 슬라이스는 거절 row UPDATE만.
- 사용자 정지는 `profiles.status='suspended'` + `suspended_at` + `suspend_reason`. 메시지 발행 차단은 `is_active_idol()` RLS 헬퍼가 자동 처리 (status='active'만 통과시킴).
- 자기 자신 정지 시도 = 400.
- 멱등성: 재정지/재해제 = 400 (현재 상태와 동일 시 명시 에러).
- 정지/해제 시 사용자 통지(푸시/이메일)는 본 슬라이스 범위 외 (notification 슬라이스 합류 시).

---

## 엣지 케이스

- **동시 승인/반려**: `WHERE id=? AND status='pending'`로 race 안전. 영향 row 0 → 409.
- **stage_name 중복 (승인 시)**: SQLAlchemy IntegrityError → 409 "활동명 중복" + 트랜잭션 롤백 → 신청 row는 여전히 pending (재처리 가능).
- **자기 정지 시도**: 400.
- **이미 정지된 관리자 (또는 일반 사용자)의 토큰으로 admin API 호출**: `AdminUser` 의존성이 `status='active'` 검증 → 403.
- **존재하지 않는 신청/사용자 id**: 404.
- **rejection_reason 빈 문자열 / 길이 초과**: Pydantic 422.
- **suspend 후 unsuspend (해제) → 즉시 재정지**: 정상 동작 (정지 사유만 새로 입력).
- **정지된 아이돌의 기존 broadcast 메시지**: 그대로 유지. 신규 발행만 차단.
- **withdrawn 상태 신청에 대한 승인/반려 시도**: 409 "이미 처리됨" (`status='pending'` 조건 미통과).

---

## 공개 인터페이스 (다른 피처가 호출 가능)

```python
# 없음. admin은 leaf 슬라이스 — 다른 피처가 호출하지 않음.
# 모든 함수는 internal로 간주.
```

---

## 어드민 웹 페이지 (참고)

본 SPEC이 어드민 웹 페이지의 데이터/액션 계약도 포함. 페이지별 책임:

### `admin/app/(admin)/signups/page.tsx` — F-035

Server Component:
- `searchParams`: `tab` (pending | approved | rejected | withdrawn, default=pending) + `page` (default=1)
- `supabase.from('idol_signup_applications').select(..., profiles!user_id(display_name)).order('created_at', { ascending: true }).range(...)`
- 컬럼: stage_name, display_name, bio (요약 2줄), application_note, created_at

Client 컴포넌트:
- `ApproveButton` / `RejectDialog` — 클릭 시 `POST /admin/idol-applications/{id}/approve` 또는 `.../reject` → 성공 시 `router.refresh()`

### `admin/app/(admin)/users/page.tsx` — F-038

Server Component:
- `searchParams`: `role`, `status`, `q` (display_name 부분 일치 또는 uuid), `includeDeleted`, `page`
- `supabase.from('profiles').select('*').ilike('display_name', \`%${q}%\`).eq('role', ...).eq('status', ...).range(...)` (조건은 q가 uuid 형식이면 `eq('id', q)`로 분기)

Client 컴포넌트:
- `SuspendDialog` (suspend_reason 입력) → `POST /admin/users/{id}/suspend`
- `UnsuspendButton` → `POST /admin/users/{id}/unsuspend`

### proxy.ts (또는 lib/supabase/middleware.ts) — F-036 게이트 보강

`/login`을 제외한 모든 경로:
1. `supabase.auth.getUser()` — 미인증 → `/login` redirect
2. `profiles` 조회 → role=admin + status=active 아니면 → `/login?error=unauthorized` redirect + 메시지

---

## 수동 테스트 시나리오 (PR에 첨부)

### 시나리오 1: F-036 role 게이트 — 일반 사용자 차단
1. 일반 fan 계정으로 어드민 웹 `/` 접근 시도
2. **기대**: `/login?error=unauthorized` redirect + "관리자 권한이 없습니다" 메시지

### 시나리오 2: F-035 승인 골든 패스
1. (사전) auth 슬라이스로 아이돌 신청 1건 생성 (status='pending')
2. 관리자로 어드민 웹 `/signups` 진입 → pending 큐에 신청 표시 확인
3. "승인" 버튼 클릭 → `POST /admin/idol-applications/{id}/approve` → 200
4. **기대**:
   - `idol_signup_applications.status='approved'`, `handled_by`/`handled_at` 채워짐
   - `idol_profiles` 새 row (stage_name, bio 복사)
   - `profiles.role='idol'`
   - 페이지 자동 refresh, 큐에서 사라짐

### 시나리오 3: F-035 반려
1. pending 신청에 "반려" 클릭 → 모달에 rejection_reason 입력 → 전송
2. **기대**: `status='rejected'`, `rejection_reason` 기입, `handled_by`/`handled_at` 채워짐
3. 신청자가 모바일 앱 cold start → `/auth/idol-pending`에서 거절 사유 표시 + 재신청 버튼 (auth 슬라이스 책임)

### 시나리오 4: F-035 승인 중 stage_name 중복
1. 기존 활성 아이돌과 같은 `stage_name`을 가진 pending 신청
2. "승인" 클릭 → 409 응답 + "활동명 중복" 메시지
3. **기대**: 신청 row 여전히 pending. 어드민이 반려 처리 후 신청자에게 다른 활동명 안내

### 시나리오 5: F-038 사용자 정지/해제
1. `/users` → 검색으로 fan 사용자 찾기 → "정지" 모달에 사유 입력 → 전송
2. **기대**: `profiles.status='suspended'`, `suspended_at`/`suspend_reason` 채워짐
3. 같은 사용자에 "해제" 클릭 → `status='active'` 복구

### 시나리오 6: F-038 자기 자신 정지 차단
1. 관리자가 자기 자신의 id로 `POST /admin/users/{self_id}/suspend` 시도
2. **기대**: 400 "자기 자신은 정지 불가"

### 시나리오 7: F-035 동시 처리 충돌
1. 같은 pending 신청에 두 관리자가 거의 동시에 "승인" 클릭
2. **기대**: 한쪽 200, 다른쪽 409 "이미 처리됨"
