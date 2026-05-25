# F-007(data) / F-014 / F-015 / F-016 채팅방 진입/리스트 — 요구사항 노트

> 작업 단위 #4 (채팅방 진입/리스트). 폴더: `features/chat_room`.
> 본 문서는 **진화하는 요구사항 공간**. 확정 항목은 → `mobile/lib/features/chat_room/SPEC.md` 로 옮긴다.

---

## 한 줄 목표

팬은 `/main`에서 응원 중인 아이돌의 채팅방 카드 리스트(최근 메시지 미리보기 + 활동명 + thumbnail)를 보고, 카드 탭으로 1:1처럼 보이는 채팅방(`/chat/:idolId`)에 진입한다. 롱프레스 시 메뉴(응원 취소/신고/알림)는 다른 피처가 슬롯 패턴으로 끼움.

---

## 요구사항

- [ ] **F-007 데이터 hookup** — profile이 만든 `chatListSlotProvider`를 본 PR에서 override해서 실제 채널 리스트 렌더. 0개일 때도 chat_room 자체의 빈 상태 위젯
- [ ] **F-014 채팅방 미리보기 카드** — 활성 subscription마다 1장. 표시: thumbnail / 활동명 / 최근 메시지 미리보기 (truncate 1줄) / 시간 (`방금 전`, `3분 전`, ...). **안 읽은 카운트는 본 PR 제외** (chat_meta 영역)
- [ ] **F-015 채팅방 메뉴 (롱프레스)** — BottomSheet로 액션 리스트. 액션 자체는 슬롯 (`chatRoomMenuActionsProvider`) — subscription / report / notification이 머지 시 자기 액션 추가. 본 PR default = 빈 리스트 + "메뉴 준비 중" 안내
- [ ] **F-016 채팅방 진입** — 라우트 `/chat/:idolId`. 화면 = AppBar(thumbnail+활동명+롱프레스로 메뉴) + 메시지 영역 슬롯 (chat_message override 대상) + 입력창 슬롯 (chat_message override 대상). 활성 subscription 아니면 진입 차단

---

## 결정 사항 (Decisions)

- `2026-05-25`: **채팅방 식별자 = `idol_id`** (1 idol = 1 채팅방 비정규화 구조). 라우트 `/chat/:idolId`. messages 테이블의 `idol_id` 컬럼이 이미 비정규화로 채워져 있음 (RLS 단일 단계 평가 위해).
- `2026-05-25`: **chat_room은 모바일 단독 작업**. 백엔드 신규 엔드포인트 없음 — Supabase 직결 (subscriptions JOIN idol_profiles + messages 최신 1개).
- `2026-05-25`: **본 PR Realtime 구독 X**. 채널 리스트는 fetch + pull-to-refresh만. broadcast 시 카드 자동 갱신은 chat_message 머지 시점에 broadcast listener가 `chatListProvider.invalidateSelf()` 호출하도록 hook 추가 예정.
- `2026-05-25`: **안 읽은 카운트는 본 PR 제외**. chat_meta(F-021) 영역 — 그 작업 단위가 카드에 카운트 슬롯을 끼우거나 카드 위젯을 갱신.
- `2026-05-25`: **채팅방 메시지 영역 + 입력창은 슬롯 패턴**. chat_room이 `chatMessageListSlotProvider` / `chatMessageInputSlotProvider` 정의 (default = placeholder). chat_message 머지 시 override.
- `2026-05-25`: **채팅방 메뉴 액션 = 슬롯 리스트 패턴**. `chatRoomMenuActionsProvider` = `Provider<List<ChatRoomMenuAction>>`. 다른 피처가 자기 액션 추가. 본 PR default = `[]` + 빈 상태 안내.
- `2026-05-25`: **활성 subscription 아니면 채팅방 진입 차단**. `/chat/:idolId` 진입 시 subscriptions 확인 → unsubscribed_at IS NULL 아니면 "응원 중인 아이돌이 아닙니다" + idol_discovery로.
- `2026-05-25`: **subscription 미머지 대응 = dev DB SQL seed**. `feature-specs/chat_room.md` 하단에 mock 1~2개 INSERT 스크립트 첨부. 사용자가 dev에서 실행해서 테스트.
- `2026-05-25`: **F-014 카드 시간 포맷 = relative** (`방금 전`, `n분 전`, `n시간 전`, `n일 전`). intl 패키지 + 자체 utility. 24시간 이상은 날짜 표시.
- `2026-05-25`: **빈 상태 (subscription 0개)** = chat_room 자체 빈 상태 위젯 ("응원 중인 아이돌이 없어요" + "아이돌 추가하기" CTA → `/discover`). profile의 default와 같은 메시지 — 다만 chat_room이 override하면 본인 위젯이 잡힘.

---

## 의문 / 미정 (Open Questions)

1. **카드 탭 vs 롱프레스 vs 스와이프 — 메뉴 트리거 UX**
   - 잠정: 롱프레스 = 메뉴 (BottomSheet), 탭 = 진입. Material 표준.
   - 스와이프 액션은 V2 검토

2. **AppBar 메뉴 (우상단 ⋮)도 같은 슬롯 액션 노출할지**
   - 잠정: O. 롱프레스 / AppBar ⋮ 둘 다 같은 액션 리스트.

3. **채팅방 진입 시 첫 fetch — 메시지 prefetch 트리거가 chat_room인가 chat_message인가**
   - 잠정: chat_message 슬롯이 자체 fetch. chat_room은 idolId만 넘김.

4. **카드 미리보기 메시지 = 마지막 idol_to_fans만? fan_to_idol(내가 보낸 것)도 포함?**
   - 잠정: 둘 다 포함. RLS가 보여주는 메시지의 최신 1개. (내 fan_to_idol + 아이돌의 idol_to_fans/idol_reply 모두)

---

## 엣지 케이스 / 메모

- subscription 이미 unsubscribed인데 카드 캐시가 stale → 진입 시 차단 + 카드 갱신
- 아이돌이 status=suspended 됨 → 채팅방 진입 차단 + "일시 정지된 아이돌" 메시지
- 메시지 0개인 새 채팅방 → "아직 메시지가 없어요" placeholder
- 본인이 아이돌인 경우 (role=idol) → 자기 채팅방은 F-024 영역 (본 작업 단위 외). chat_room은 팬 화면 전용
- 라우트 `/chat/:idolId`의 idolId가 잘못된 UUID → 404 fallback
- 활성 subscription 0개일 때 빈 상태 + CTA → `/discover` 미머지 시 토스트 fallback (profile에서 검증된 패턴 재사용)
- 카드 정렬 = 최근 메시지 created_at DESC (메시지 없으면 subscription.subscribed_at 사용)

---

## SPEC.md 로 승격된 항목

- [ ] 화면 라우트 (`/chat/:idolId`)
- [ ] 읽기 테이블 (subscriptions, idol_profiles, messages 최신 1)
- [ ] 슬롯 인터페이스 (chatMessageListSlotProvider, chatMessageInputSlotProvider, chatRoomMenuActionsProvider)
- [ ] 비즈니스 룰 (진입 차단 조건, 빈 상태, 메뉴 패턴)

---

## Mock 데이터 SQL (dev 테스트용)

subscription/idol_discovery 미머지 상태에서 채팅방 카드를 보려면 dev DB에 다음 INSERT 실행 (사용자가 본인 fan_id로 수정):

```sql
-- 1. 테스트 아이돌 2명 생성 (실제 auth.users 미존재 → FK 위반 가능. supabase_admin으로 raw INSERT)
-- 단 profiles.id는 auth.users.id에 FK이므로 supabase auth admin API로 user 먼저 생성하거나,
-- 이미 존재하는 test-*@gihagochi-test.local 사용자를 idol로 승격.

-- 옵션 A: 기존 test 사용자를 idol로 승격 (가장 안전)
UPDATE profiles
   SET role='idol'::user_role, status='active'::user_status, display_name='테스트 아이돌 A'
 WHERE id = 'fbf20c59-6f7a-43b0-95ff-16a4db0b2220';

UPDATE profiles
   SET role='idol'::user_role, status='active'::user_status, display_name='테스트 아이돌 B'
 WHERE id = '907803a5-1b4b-43ac-9daf-1494820413c7';

-- 단, 이 사용자들은 profiles row가 없을 수도. 그 경우 먼저 INSERT (RLS 우회 = service_role 또는 superuser):
INSERT INTO profiles (id, role, status, display_name)
VALUES
  ('fbf20c59-6f7a-43b0-95ff-16a4db0b2220', 'idol'::user_role, 'active'::user_status, '테스트 아이돌 A'),
  ('907803a5-1b4b-43ac-9daf-1494820413c7', 'idol'::user_role, 'active'::user_status, '테스트 아이돌 B')
ON CONFLICT (id) DO UPDATE SET role='idol'::user_role, status='active'::user_status;

-- 2. idol_profiles 행 — signup_application_id가 NOT NULL FK라 idol_signup_applications도 필요.
--    simplification: dummy application 먼저 생성.
INSERT INTO idol_signup_applications (id, applicant_id, stage_name, status)
VALUES
  (gen_random_uuid(), 'fbf20c59-6f7a-43b0-95ff-16a4db0b2220', '아이돌A', 'approved'),
  (gen_random_uuid(), '907803a5-1b4b-43ac-9daf-1494820413c7', '아이돌B', 'approved')
RETURNING id, applicant_id;
-- 위 결과의 id를 아래에 사용:
INSERT INTO idol_profiles (id, signup_application_id, stage_name)
SELECT applicant_id, id, stage_name
  FROM idol_signup_applications
 WHERE applicant_id IN ('fbf20c59-6f7a-43b0-95ff-16a4db0b2220', '907803a5-1b4b-43ac-9daf-1494820413c7')
ON CONFLICT (id) DO NOTHING;

-- 3. 본인이 두 아이돌 응원 (subscription)
INSERT INTO subscriptions (fan_id, idol_id)
VALUES
  ('94f25370-f5e4-44a0-a461-c59de4856190', 'fbf20c59-6f7a-43b0-95ff-16a4db0b2220'),
  ('94f25370-f5e4-44a0-a461-c59de4856190', '907803a5-1b4b-43ac-9daf-1494820413c7')
ON CONFLICT (fan_id, idol_id) DO NOTHING;

-- 4. (선택) 아이돌이 메시지 발행 — 카드 미리보기 채우기
INSERT INTO messages (type, sender_id, idol_id, content, media_type)
VALUES
  ('idol_to_fans'::message_type, 'fbf20c59-6f7a-43b0-95ff-16a4db0b2220',
   'fbf20c59-6f7a-43b0-95ff-16a4db0b2220', '안녕! 오늘 콘서트 잘 끝났어 💜', 'text'::media_type),
  ('idol_to_fans'::message_type, '907803a5-1b4b-43ac-9daf-1494820413c7',
   '907803a5-1b4b-43ac-9daf-1494820413c7', '내일 라이브 방송 보러 와줘!', 'text'::media_type);
```

> 위 SQL은 본 PR 셀프 점검 시 작성자가 dev에 직접 실행. 알렘빅 migration X (테스트 시드는 코드에 안 들어감).
> 본 PR 머지 후엔 별도 admin/idol_discovery/subscription 작업으로 자연스럽게 시드 불필요.

---

## 참고

- 작업 단위 매핑: `docs/FEATURES.md` §2 (#4 채팅방 진입/리스트)
- 피처 상세: `docs/FEATURES.md` §3.3
- 의존 매트릭스: `docs/FEATURES.md` §10.1 (chat_room 선행 = idol_discovery, subscription)
- profile의 슬롯 인터페이스: `mobile/lib/features/profile/SPEC.md`의 `chatListSlotProvider`
- DB 스키마: `backend/app/shared/models/{subscription,message,message_read}.py`
- 제품 헌법: `docs/FEATURES.md` §9 — 메시지 1개 = DB row 1개 (fan-out 시 row 복사 X)
