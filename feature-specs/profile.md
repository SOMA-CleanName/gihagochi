# F-007 / F-028 / F-030 / F-032 / F-034 마이페이지 — 요구사항 노트

> 작업 단위 #9 (마이페이지). 폴더: `features/profile`.
> **F-024 (아이돌 메인)는 본 단위에서 제외** — chat 도메인으로 후속 재배치 (`docs/FEATURES.md` §10.4 이슈 #1). 본 PR은 팬 마이페이지 중심 + 아이돌 임시 진입점.
> 본 문서는 **진화하는 요구사항 공간**. 확정 항목은 → `mobile/lib/features/profile/SPEC.md` 로 옮긴다.

---

## 한 줄 목표

팬은 응원 중인 아이돌 목록과 자기 프로필/계정/약관을 한 화면에서 관리하고, 진입 직후 팬 메인(채팅방 리스트 shell)으로 안착한다. 아이돌은 본격 메인 화면(F-024) 머지 전까지 마이페이지를 임시 진입점으로 사용한다.

---

## 요구사항

- [ ] **F-007 메인 페이지 (팬) — 채팅방 리스트 shell**
  - 응원 중 아이돌 0명일 때 빈 상태 화면 + "아이돌 추가하기" CTA (idol_discovery로 라우팅)
  - 응원 중 1명 이상일 때 채팅방 카드 리스트 (**데이터 연결은 chat_room 머지 시점**; profile은 빈 상태 + 스켈레톤만)
  - 하단 네비: 메인 / 마이페이지 (2탭 시작, 추후 확장)
- [ ] **F-028 마이페이지 (팬)** — 다음 섹션을 카드/리스트로 표시:
  - 프로필 카드 (avatar + display_name + "편집" 버튼 → F-030)
  - 응원 중인 아이돌 (구독 리스트 — **subscription 머지 시점 연결**, 1차는 placeholder)
  - 알림 설정 진입 (**notification 머지 시점 연결**, 1차는 placeholder)
  - 계정·보안 → F-032
  - 약관/개인정보/고객센터 → F-034
  - 로그아웃 (auth의 logout 호출)
- [ ] **F-030 프로필 편집**
  - 팬: `display_name`, `avatar_url` 만 수정
  - 아이돌: 활동명(`idol_profiles.stage_name`), 소개(`bio`) — 1차는 **관리자 승인 없이 즉시 반영**. 운영 데이터 보고 차후 승인 플로우 추가 검토
  - avatar 업로드: Supabase Storage `avatars` 버킷 (private + signed URL)
- [ ] **F-032 계정/보안**
  - 비밀번호 변경: **숨김** (auth가 Google OAuth only이므로 N/A). 대신 "Google 계정에서 관리" 안내 텍스트
  - 회원 탈퇴: **soft delete** — `profiles.deleted_at = NOW()` UPDATE. 메시지/구독은 보존. 30일 후 hard delete (운영 자동화는 본 PR 범위 외)
  - `deleted_at` 컬럼은 [profile.py:47](backend/app/shared/models/profile.py#L47)에 이미 존재 — 마이그레이션 0개
- [ ] **F-034 약관/개인정보/고객센터**
  - 약관 / 개인정보 처리방침: 정적 페이지 (assets/legal/*.md → flutter_markdown으로 렌더링)
  - 1차 문안 미확보 → placeholder 텍스트 + 메인 빌더에 문안 요청 (출시 전 필수)
  - 고객센터: `mailto:` 링크 (지원 이메일 1차). Jotform 등 외부 폼 도입은 운영 시 검토

---

## 결정 사항 (Decisions)

- `2026-05-25`: **F-024 (아이돌 메인) 본 단위에서 제외**. 이유: F-025(메시지 발행)와 같은 화면 → chat 도메인 강결합. `docs/FEATURES.md` §2/§10.1 갱신은 별도 `docs/` PR로 분리 또는 본 PR에 동봉(메인 빌더 판단). 잠정: 본 PR에선 코드만 작업, docs 갱신은 분리.
- `2026-05-25`: **profile은 모바일 단독 작업**. 백엔드 신규 엔드포인트 없음 — 모두 Supabase 직통 (profiles UPDATE, storage upload, RLS). 회원 탈퇴 cascade가 RLS만으로 안 되면 인지 트리거.
- `2026-05-25`: **F-007 채팅방 리스트 데이터 연결 보류** — profile은 빈 상태/스켈레톤만 구현. chat_room 머지 시 그쪽 작업자가 widget 끼움. 본 PR의 SPEC.md "공개 인터페이스"에 `MainScreen` widget이 어디서 chat list slot을 받는지 명시.
- `2026-05-25`: **아이돌 활동명/소개 수정은 1차 즉시 반영** (관리자 승인 없음). 이유: 운영 초기 빈도 낮음 + 승인 큐 부담 회피. 부작용 발생 시 차후 도입.
- `2026-05-25`: **비밀번호 변경 UI 없음** — auth가 Google OAuth only라 자명. "Google 계정에서 관리" 안내만.
- `2026-05-25`: **회원 탈퇴 = soft delete**. `profiles.deleted_at = NOW()` UPDATE. 컬럼 이미 존재 → 마이그레이션 0. 메시지/구독 보존. 30일 후 hard delete cron은 본 PR 범위 외 (운영 자동화).
- `2026-05-25`: **아이돌 편집 필드 = `stage_name`, `bio`, `thumbnail_url`**. [idol_profile.py](backend/app/shared/models/idol_profile.py) OWNER 주석에 `profile (편집, F-030)` 명시되어 UPDATE 권한 있음. avatar(profiles)와 thumbnail(idol_profiles)는 별개 — UI에서 둘 다 노출.
- `2026-05-25`: **팬 메인 라우트 = `/main`** (root `/`는 그대로 placeholder 유지). auth가 가입 후 `/discover`로 보내는 흐름은 그대로. `/main`은 마이페이지 / 추후 네비바에서 진입. core/router placeholder는 안 건드림.
- `2026-05-25`: **약관 1차 = placeholder + assets 정적 마크다운**. 문안 확보는 메인 빌더 책임 (출시 전 필수, 본 PR 범위 외).
- `2026-05-25`: **하단 네비 = 2탭** (메인 / 마이페이지). idol_discovery / notification 추가 시 확장.
- `2026-05-25`: **아이돌 임시 진입점 = 마이페이지**. 아이돌 로그인 시 본격 메인(F-024) 머지 전까지 마이페이지로 라우팅. 마이페이지 상단에 "메시지 발행은 준비 중" 안내 배너.

---

## 의문 / 미정 (Open Questions)

남은 결정 — 구현 시점 또는 사용자 확인 필요.

1. **약관 버전 변경 시 재동의 플로우 위치**
   - auth (가입 시 동의) vs profile (기존 사용자 재동의 모달)
   - 잠정: 재동의 모달은 profile 책임. 단 본 PR 범위 외 — 차후 별도 작업 단위로

2. **avatar / thumbnail 업로드 시 크기/포맷 제한**
   - 잠정: 5MB 이하, JPEG/PNG만, 클라 리사이즈 (avatar 512x512 / thumbnail 1024x1024). 코드 작성하며 결정 OK

3. **응원 중 아이돌 placeholder UX**
   - subscription 머지 전 "구독 기능 준비 중" 회색 카드? 아예 섹션 숨김?
   - 잠정: 회색 카드 + "준비 중" 텍스트

---

## 엣지 케이스 / 메모

- avatar 업로드 중 실패 → 기존 avatar 유지, 토스트로 에러 표시
- 회원 탈퇴 확정 모달 — "정말 탈퇴하시겠습니까? 30일 내 재로그인 시 복구됩니다" 문구. 복구 플로우는 본 PR 범위 외 (메인 빌더 영역)
- 아이돌이 본인 idol_signup_applications 거절 상태 진입 시 → 마이페이지 상단에 거절 사유 표시 + 재신청 진입점. 단 재신청 UI는 auth 영역이므로 본 PR은 표시만
- 약관 페이지 외부 링크 vs WebView vs 정적 마크다운 — 정적 마크다운으로 시작 (오프라인 OK, 빠름)
- 마이페이지에서 아이돌 / 팬 분기 — `profiles.role` 기반. 아이돌은 추가로 "메시지 발행 준비 중" 배너, 팬은 응원 중 아이돌 섹션
- 비로그인 상태 진입 방어 — auth_guard가 처리 (이미 있음)
- 로그아웃 → auth router가 로그인 화면 복귀 처리. 별도 라우팅 정의 불필요

---

## SPEC.md 로 승격된 항목

확정되어 SPEC.md(계약)로 옮긴 항목 체크.

- [ ] 화면 라우트 (`/main`, `/my`, `/my/edit`, `/my/account`, `/my/legal/*`)
- [ ] 읽기/쓰기 테이블 (profiles, idol_profiles, terms_agreements 읽기 / profiles UPDATE)
- [ ] Supabase Storage 버킷 사용 (`avatars`)
- [ ] 공개 인터페이스 (다른 피처가 끼울 수 있는 슬롯 — MainScreen 채팅 리스트 slot, 마이페이지 응원 중 슬롯)
- [ ] 비즈니스 룰 (탈퇴 = soft delete, 활동명 즉시 반영, 비번 변경 UI 없음)

---

## 참고

- 작업 단위 매핑: `docs/FEATURES.md` §2 (#9 마이페이지)
- 피처 상세: `docs/FEATURES.md` §3.4
- 의존 매트릭스: `docs/FEATURES.md` §10.1 (profile 선행 = auth만)
- F-024 재배치 검토: `docs/FEATURES.md` §10.4 이슈 #1
- auth 결정 사항 (이메일/role/status/terms 스키마): `feature-specs/auth.md`
- DB 스키마: `backend/migrations/versions/0001_initial.py`, `backend/app/shared/models.py`
