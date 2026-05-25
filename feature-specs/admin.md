# F-035 / F-036 / F-038 관리자 — 요구사항 노트

> 작업 단위 #11 (관리자: 가입/사용자/로그인). 폴더: `features/admin`.
> 본 문서는 **진화하는 요구사항 공간**. 확정 항목은 →
> `backend/app/features/admin/SPEC.md` (계약) 로 옮긴다.
> 어드민 웹 페이지(`admin/app/(admin)/signups`, `.../users`)는 별도 SPEC.md 두지 않고
> 백엔드 SPEC을 단일 진실의 원천으로 사용 (admin 슬라이스는 페이지가 N개).

---

## 한 줄 목표

관리자가 어드민 웹에서 (1) **아이돌 가입 신청을 승인/반려**하고, (2) **사용자/아이돌 활동을 조회·정지·해제**하며, (3) 일반 사용자가 어드민 라우트에 진입하지 못하도록 **role 게이트로 가드**한다.

---

## 요구사항

### F-036 관리자 로그인 (게이트 보강)

- [ ] 어드민 웹 `/login` 화면은 **이미 auth 슬라이스에서 셸 완성**(`admin/app/login/`). 본 슬라이스는 **role 게이트 보강**만:
  - `proxy.ts` (또는 `lib/supabase/middleware.ts`)에서 세션 확인 + `profiles.role='admin' AND status='active'` 검증
  - 미인증 → `/login`
  - 인증됐지만 role≠admin → `/login?error=unauthorized` + 메시지 표시
- [ ] 정지된 관리자(`status='suspended'`)는 로그인 시도 시 차단

### F-035 아이돌 가입 신청 승인/반려

- [ ] `/signups` — 신청 큐 리스트 (FIFO: `created_at ASC`)
  - pending 신청만 표시 (기본 탭)
  - 탭 또는 필터로 approved / rejected / withdrawn 이력 조회
  - 컬럼: stage_name, display_name (신청자), bio 요약, application_note, 신청일
- [ ] 승인 액션 (백엔드 API 트랜잭션):
  - `POST /admin/idol-applications/{id}/approve`
  - 단일 트랜잭션: `idol_signup_applications.status='approved'` UPDATE + `idol_profiles` INSERT + `profiles.role='idol'` UPDATE
  - `idol_profiles.stage_name` UNIQUE 충돌 시 → 트랜잭션 롤백 + 409 응답
- [ ] 반려 액션 (백엔드 API):
  - `POST /admin/idol-applications/{id}/reject` body: `{ rejection_reason: str }`
  - `idol_signup_applications.status='rejected'` UPDATE + `rejection_reason` 기입
- [ ] 처리한 관리자(`handled_by`, `handled_at`) 기록
- [ ] 신청자 본인의 신청 read 진입은 auth 슬라이스(`/auth/idol-pending`)가 처리. admin은 책임 X

### F-038 사용자/아이돌 관리

- [ ] `/users` — 사용자 리스트 (offset/limit, 20행/페이지)
  - 필터: role (fan/idol/admin) × status (active/pending/suspended) × deleted 포함 토글
  - 검색: display_name 부분 일치, id (uuid) 직접 검색
  - 컬럼: display_name, role, status, 가입일, 정지 여부, 정지 사유
- [ ] 사용자 정지 (백엔드 API):
  - `POST /admin/users/{id}/suspend` body: `{ suspend_reason: str }`
  - `profiles.status='suspended'` + `suspended_at=NOW()` + `suspend_reason` 기입
- [ ] 사용자 해제 (백엔드 API):
  - `POST /admin/users/{id}/unsuspend`
  - `profiles.status='active'` + `suspended_at=NULL` + `suspend_reason=NULL`
- [ ] 아이돌 활동 일시중지/재개 = 사용자 정지/해제로 통합 (`profiles.status='suspended'` 재사용). 스키마 변경 없음
- [ ] 자기 자신 정지 시도 → 400 차단
- [ ] (선택, 본 PR 후순위) 사용자 상세 모달 — 응원 중 아이돌 수, 최근 메시지 수, 신고 이력 카운트

---

## 결정 사항 (Decisions)

본 슬라이스 작업 중 합의되어 잠긴 항목.

- `2026-05-25`: **어드민 웹 페이지 경로 = `/signups`, `/users`** (가칭 그대로 채택). `(admin)` route group 안에 들어가 인증 가드 묶음.
- `2026-05-25`: **관리자 액션 처리 경로 = 혼합** (Q#3 옵션 c).
  - **트랜잭션 / 사이드이펙트가 있는 mutation** → 백엔드 API (`POST /admin/...`), `AdminUser` 의존성 + service_role로 처리
  - **단순 SELECT (리스트/검색/필터)** → 어드민 웹 Server Component에서 `lib/supabase/server` 직접 호출 (사용자 JWT + RLS의 admin 정책)
  - 이유: 승인 같은 트랜잭션은 트랜잭션 경계 보장 필요 + idol_profiles INSERT/profiles UPDATE/applications UPDATE 3-step. 리스트는 Server Component가 SSR 친화적이라 단순.
- `2026-05-25`: **RLS 마이그레이션 없음**. `SCHEMA.md` §5의 `is_admin()` 헬퍼와 기존 admin 정책 그대로 사용. 어드민 웹 SELECT가 RLS로 동작 OK인지 dev 환경에서 검증.
- `2026-05-25`: **`idol_signup_applications` contract** — auth = INSERT (status='pending') only / admin = UPDATE (status, handled_by, handled_at, rejection_reason). 양쪽 SPEC.md에 명문화. DB 컬럼은 추가 없음.
- `2026-05-25`: **첫 admin user 생성은 본 PR 범위 외** (Open Q#2). Supabase Studio에서 메인 빌더가 `UPDATE profiles SET role='admin', status='active' WHERE id='<uuid>';` 수동 1회. 차후 CLI 스크립트 검토.
- `2026-05-25`: **사용자 검색 필드 = display_name 부분 일치 + id (uuid) 정확 일치**. email 검색은 1차 제외 (auth.users join 복잡도).
- `2026-05-25`: **신청 큐 정렬 = `created_at ASC`** (FIFO).
- `2026-05-25`: **아이돌 활동 일시중지 메커니즘 = `profiles.status='suspended'` 재사용** (Q#8 옵션 a). 스키마 변경 없음. 메시지 발행 차단은 `is_active_idol()` RLS 헬퍼가 이미 status='active'를 보므로 자동 적용.
- `2026-05-25`: **정지/해제 시 통지(푸시/이메일) 본 PR 범위 외**. notification 슬라이스 합류 시 검토.
- `2026-05-25`: **페이지네이션 = offset/limit, 페이지당 20행**. 어드민 트래픽 적어 cursor 불필요.
- `2026-05-25`: **F-037 신고 처리는 본 PR 범위 외** — `features/report` 슬라이스로 분리.
- `2026-05-25`: **재정지 / 재해제 멱등성 = 400 응답**. 현재 상태와 동일하면 명시 에러로 클라이언트에 신호.
- `2026-05-25`: **사용자 상세 모달 본 PR 제외** (Q-잔여 #1). 1차 PR 크기 관리 위해. 후속 `admin-detail` PR로 분리.
- `2026-05-25`: **첫 admin user CLI 스크립트 본 PR 제외** (Q-잔여 #2). 메인 빌더가 Supabase Studio 수동 SQL로 처리. 스크립트화는 운영 빈도 보고 결정.
- `2026-05-25`: **거절 사유 prefill / 템플릿 본 PR 제외** (Q-잔여 #3). 단순 textarea만 노출. 운영팀이 자주 쓰는 사유 패턴 누적되면 후속 PR로 prefill 옵션 추가.

---

## 의문 / 미정 (Open Questions)

(모두 결정됨. 본 슬라이스 작업 중 새 미정 발생 시 여기에 추가.)

---

## 엣지 케이스 / 메모

- **동시 처리 충돌**: 두 관리자가 같은 pending 신청을 동시에 승인/반려 → `UPDATE ... WHERE status='pending'`으로 영향 row 0이면 409 "이미 처리됨"
- **stage_name UNIQUE 충돌 (승인 시)**: 트랜잭션 롤백 + 409 "기존 아이돌과 중복" — 거절 후 신청자에게 다른 활동명 안내
- **자기 자신 정지 시도**: `target_user_id == auth.uid()` 체크 → 400
- **정지된 관리자의 로그인 시도**: proxy에서 `status='active'` 체크하므로 자동 차단
- **이미 active인 사용자 재정지 / 이미 suspended 사용자 재해제**: 400 응답 (멱등 noop 아님, 명시 에러)
- **정지된 아이돌의 기존 broadcast 메시지**: 그대로 유지 (보존). 신규 발행만 차단 (is_active_idol이 status 보니까 자동)
- **신청 큐 비어있을 때 UX**: "처리할 신청이 없습니다" empty state
- **withdrawn 처리**: 신청자가 직접 (auth 슬라이스). admin은 표시만
- **관리자 권한 부여 자체는 본 PR 범위 외** — 메인 빌더 수동 SQL

---

## SPEC.md 로 승격된 항목

- [x] 어드민 웹 페이지 경로 / 디렉터리 구조 (Q#1)
- [x] 관리자 액션 처리 경로 — backend API + Server Action 혼합 (Q#3)
- [x] 백엔드 API 엔드포인트 명세 (Q#3 결정 후)
- [x] 읽기/쓰기 테이블 + `idol_signup_applications` contract (Q#5)
- [x] 공개 인터페이스 — **없음** (admin은 leaf, 다른 슬라이스가 호출 X)
- [x] 비즈니스 룰 (트랜잭션 / 멱등성 / 자기 정지 차단)

---

## 참고

- 작업 단위 매핑: `docs/FEATURES.md` §2 (#11 관리자), §10.1
- 피처 상세: `docs/FEATURES.md` §3.7
- DB 스키마: `docs/SCHEMA.md` (`profiles` / `idol_signup_applications` / `idol_profiles` 섹션)
- auth 슬라이스 SPEC: `backend/app/features/auth/SPEC.md` (idol_signup_applications INSERT 패턴)
- 어드민 웹 stack 룰: `admin/AGENTS.md` (Next.js 16, proxy.ts, supabase server client 분리)
