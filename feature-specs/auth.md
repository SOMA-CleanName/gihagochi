# F-001 ~ F-006 인증/계정 — 요구사항 노트

> 작업 단위 #1 (가입/로그인). 폴더: `features/auth`.
> 본 문서는 **진화하는 요구사항 공간**. 확정 항목은 → `features/auth/SPEC.md` (backend + mobile) 로 옮긴다.

---

## 한 줄 목표

팬과 아이돌이 소셜 로그인으로 가입/로그인하고, 아이돌은 관리자 승인을 거쳐야 활성화되며, 모든 후속 피처는 이 인증 상태를 기반으로 동작한다.

---

## 요구사항

- [ ] F-001 팬 회원가입 — 소셜 로그인 (이메일/비밀번호 없음)
- [ ] F-002 아이돌 회원가입 — 소셜 로그인 + 가입 후 "승인 대기" 상태로 진입, 관리자가 승인해야 활성화
- [ ] F-003 로그인 — 동일 소셜 계정으로 로그인. 사용자 타입(팬/아이돌)에 따라 진입 화면 분기
- [ ] F-004 자동 로그인 / 토큰 갱신 — Supabase가 refresh 자동 처리. refresh 만료 시 로그인 화면 강제 이동
- [ ] F-005 로그아웃 — 마이페이지에서. Supabase 세션 종료
- [ ] ~~F-006 비밀번호 재설정~~ — 본 PR 제외 (소셜 only라 사실상 불필요. 차후 결정)

---

## 결정 사항 (Decisions)

- `2026-05-20`: **인증 백엔드 = Supabase Auth** 그대로 사용. 자체 JWT 발급 X. 이유: 셋업 단순화 + Supabase가 RLS와 통합되어 있어 후속 피처(메시지 등) 권한 처리 편함.
- `2026-05-20`: **가입 방식 = 소셜 로그인만**. 이메일/비밀번호 미지원. F-006(비번 재설정)은 자동 N/A.
- `2026-05-20`: **아이돌 가입 후 상태 = "승인 대기"**. 로그인 자체는 성공하지만, 아이돌 기능은 잠금. 승인 전엔 "승인 대기 중" 화면만 표시. 관리자가 admin 웹에서 승인하면 활성화.
- `2026-05-20`: **세션 정책 = Supabase 기본값** (access 1h, refresh 30d rotating). 별도 커스터마이즈 없음 ("알아서 적당히" 위임). Studio Settings → Auth에서 조정 가능.
- `2026-05-20`: **F-006 비밀번호 재설정은 본 PR 제외**. 소셜 only라 즉시 필요성 없음.
- `2026-05-20`: **profiles 스키마는 0001_initial 그대로 사용** — `role` ENUM('fan'/'idol'/'admin'), `status` ENUM('pending'/'active'/'suspended'), `display_name`, `avatar_url`. 추가 컬럼 불필요. (미정 #5 해결)
- `2026-05-20`: **아이돌 신청은 `idol_signup_applications` 테이블로 별도 트랙** — DB가 이미 분리되어 있어 "일단 팬 가입 → 아이돌 신청 별도 화면" UX가 자연스러움. (미정 #2 옵션 B/C로 수렴 — 세부는 아래)
- `2026-05-20`: **약관 동의는 `terms_agreements` 테이블에 version별로 기록**. 가입 플로우에 동의 단계 필수. `agreement_type` ENUM = `'tos'`, `'privacy'`, `'marketing'`. tos/privacy 필수, marketing 선택. (미정 #4 부분 해결, 노출 위치는 UX 결정)
- `2026-05-20`: **소셜 제공자 = Google + Apple + Kakao 3개** (1차 출시). Naver는 P2 재검토 항목으로 보류.
  - Google/Apple/Kakao: **모두 Supabase Auth가 native OAuth provider로 지원** (https://supabase.com/docs/guides/auth/social-login/auth-kakao 확인). `supabase.auth.signInWithOAuth({ provider })` 단일 API로 처리.
  - 결과: **mobile native SDK 추가 불필요**. 인지 트리거 #2(pubspec.yaml 변경) 자동 해소.
  - 메인 빌더 작업: Supabase Studio → Authentication → Providers에서 Google/Apple/Kakao 활성 + 각 client_id/secret 입력 (각 Developer Portal에서 발급). 콜백 URL `https://<project-ref>.supabase.co/auth/v1/callback`을 각 OAuth 앱 설정에 등록.
- `2026-05-20`: **사용자 타입 분기 = 옵션 C** (가입 화면에서 "팬으로 가입" vs "아이돌로 가입" 선택)
  - 일반(팬) 가입: profiles INSERT (`role='fan', status='active'`) — 즉시 활성
  - 아이돌 가입: profiles INSERT (`role='fan', status='active'`) + idol_signup_applications INSERT (`status='pending'`) → 승인 전까지 팬 기능은 사용 가능, 아이돌 기능만 잠금. 승인 시 `profiles.role='idol'` UPDATE + `idol_profiles` INSERT.
  - 거절 시: `idol_signup_applications.status='rejected'` + `rejection_reason`. 재신청 가능 (새 row).
- `2026-05-20`: **약관 노출 = 가입 화면 하단 체크박스** (소셜 버튼 누르기 전). tos/privacy 필수 체크 안 하면 버튼 비활성. marketing은 선택 체크박스.

---

## 의문 / 미정 (Open Questions)

남은 결정 — 구현 시점 또는 다른 피처 작업 시 정제.

1. ~~Kakao/Naver OAuth 구현 경로~~ — **해결**: Kakao는 Supabase native, Naver는 1차 제외 결정 (위 Decisions 참조).

2. **아이돌 신청 거절 사유 표시 UX 디테일**
   - "승인 대기" 화면에서 `rejection_reason` 노출 방식 (전체 텍스트? 요약 + "자세히" 토글?)
   - 재신청 시 이전 신청 데이터 prefill 여부

3. **소셜 가입 시 같은 이메일이 두 제공자에서 오는 경우 통합 정책**
   - Supabase는 별도 user로 본다. 사용자에게 "이미 가입된 계정" 알림 + 기존 계정으로 로그인 유도 / 또는 별도 계정 허용?
   - MVP는 별도 계정 허용 가정. 차후 신고 패턴 보고 정책 재검토.

---

## 엣지 케이스 / 메모

- 소셜 가입 시 같은 이메일이 두 제공자에서 오는 경우 (Google + Apple 둘 다 같은 이메일) → Supabase Auth는 별도 user로 본다. 통합 정책 필요?
- 아이돌이 자기 계정을 팬 계정으로도 쓰고 싶어할 가능성 → 1계정 1역할 강제? 또는 역할 전환?
- 토큰 만료 중 백엔드 요청 → Supabase SDK가 refresh 자동, 실패 시 401 → 로그인 화면 이동
- 소셜 가입 후 첫 로그인 vs 재로그인 분기 (가입 직후 약관 동의 화면? 또는 한 번 동의하면 끝?)
- 회원 탈퇴 처리 (F-032와 연계) — auth에 탈퇴 API는 안 포함. profiles 레코드 어떻게 처리할지는 F-032에서.

---

## SPEC.md 로 승격된 항목

확정되어 SPEC.md(계약)로 옮긴 항목 체크.

- [ ] API 엔드포인트 명세 — Open Questions 1~4 확정 후
- [ ] 읽기/쓰기 테이블 — Open Question 5 확정 후
- [ ] 공개 인터페이스 (다른 피처가 호출할 함수) — `get_current_user`, `require_role` 등
- [ ] 비즈니스 룰 — 승인 대기 상태 처리, 사용자 타입 분기

---

## 참고

- 작업 단위 매핑: `docs/FEATURES.md` §2 (#1 가입/로그인)
- 피처 상세: `docs/FEATURES.md` §3.1
- DB 스키마: `docs/SCHEMA.md` *(작성 예정)*
- Supabase Auth 문서: https://supabase.com/docs/guides/auth
