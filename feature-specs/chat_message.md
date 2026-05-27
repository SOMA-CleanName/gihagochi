# F-017 / F-018 / F-022 / F-025 / F-026 메시지 송수신 — 요구사항 노트

> 작업 단위 #5 (메시지 송수신). 폴더: `features/chat_message`.
> **§10.4 이슈 #3 권장 분할 — 진행 현황**:
>   - **core PR #41 (머지됨)**: F-017 (팬→아이돌), F-018 (1:N 수신), F-022 (페이지네이션)
>   - **F-025 (아이돌 발행) — PR #60에서 사실상 처리됨**: `sendIdolBroadcast` + role 기반 분기. 입력 UI 재사용
>   - **admin PR (이 PR)**: F-026 (수정/삭제) — 같은 폴더에 점진 추가
>
> 본 문서는 **진화하는 요구사항 공간**. 확정 항목은 → `mobile/lib/features/chat_message/SPEC.md` 로 옮긴다.

---

## 한 줄 목표

팬은 `/chat/:idolId` 채팅방에서 자기가 보낸 메시지와 아이돌이 broadcast한 메시지를 시간순(ASC, 오래된 위)으로 보고, 새 메시지는 Realtime으로 즉시 도착하며, 위로 스크롤하면 과거 메시지가 추가 로딩된다. 본 PR은 텍스트 메시지만 — 사진/음성은 chat_media 영역.

---

## 요구사항 (core PR — 머지됨)

- [x] **F-017 팬→아이돌 텍스트 전송** — PR #41
- [x] **F-018 1:N broadcast 수신** — PR #41
- [x] **F-022 페이지네이션** — PR #41
- [x] **chat_room 슬롯 override** — PR #41
- [x] **chat_room 카드 자동 갱신** — PR #41

---

## 요구사항 (F-025 아이돌 발행 — PR #60에서 처리)

- [x] **F-025 아이돌 메시지 발행** — PR #60 `sendIdolBroadcast` 메서드 + `_sendByRole` 분기 (현재 사용자 == idol_id면 broadcast, 그 외 fan_to_idol). 입력 UI 재사용.

---

## 요구사항 (admin PR — 이 PR)

- [ ] **F-026 메시지 수정** — 본인 메시지 롱프레스 → "수정" → 기존 텍스트 prefill 다이얼로그 → `messages` UPDATE (`content`, `edited_at = NOW()`). 시간 제한 없음 (사용자 결정).
- [ ] **F-026 메시지 삭제 (soft delete)** — 본인 메시지 롱프레스 → "삭제" 확인 모달 → `messages` UPDATE (`deleted_at = NOW()`). 시간 제한 없음. 다른 팬 화면에서는 즉시 "(삭제된 메시지)" placeholder로 갱신 (UPDATE Realtime 이벤트 구독).
- [ ] **Realtime UPDATE 이벤트 구독 추가** — 채팅방 진입 시 INSERT + UPDATE 둘 다 구독. UPDATE 도착 시 해당 message id 매칭하여 state 교체.
- [ ] **수정된 메시지 표시** — `edited_at != null` 인 메시지는 시각 옆에 "(수정됨)" 라벨 작게 표시.
- [ ] **삭제된 메시지 표시** — `deleted_at != null` 인 메시지는 본문을 "(삭제된 메시지)" placeholder로 교체 (이미 core PR에서 처리되어 있음).

---

## 본 PR 제외 (후속 작업)

- F-019 (사진), F-020 (음성) — chat_media 영역. PR #62~#64 머지 완료.
- F-021 (읽음 처리), F-023 (답장 표시) — chat_meta 영역. PR #61 머지 완료.
- 타이핑 인디케이터, 새 메시지 알림 뱃지 — 향후

---

## 결정 사항 (Decisions)

- `2026-05-25`: **모바일 단독 작업**. 백엔드 API 없음. messages RLS는 이미 0001_initial에 완비됨 (INSERT/SELECT/UPDATE 각각 정의됨). Realtime은 supabase_flutter SDK가 자동 처리.
- `2026-05-25`: **Realtime publication 활성화 필요** — dev DB에 `ALTER PUBLICATION supabase_realtime ADD TABLE messages;` 실행. 메인 빌더 영역 변경 — 사용자 사전 승인 받고 asyncpg로 적용 (이전 storage RLS / mock seed 패턴).
- `2026-05-25`: **Realtime 구독 단위 = 채팅방별** (`messages` 테이블 INSERT 이벤트 + filter `idol_id=eq.<idolId>`). 채팅방 진입 시 구독, 이탈 시 해제. 멀티 채널 동시 구독 X (현재 보고 있는 채팅방만).
- `2026-05-25`: **메시지 정렬 = `created_at` ASC** (오래된 위, 최신 아래). 채팅방 진입 시 자동 스크롤 끝 (최신).
- `2026-05-25`: **fan_to_idol 멱등성 = `client_message_id` UUID v4 생성** + DB의 `(sender_id, client_message_id)` unique partial index에 의존. 재전송 시 같은 client_message_id → 중복 INSERT 차단.
- `2026-05-25`: **메시지 표시 규칙** — 본인 메시지(fan_to_idol where sender=me) = 오른쪽 정렬 + bubbleMine 색. 아이돌 메시지(idol_to_fans/idol_reply) = 왼쪽 정렬 + bubbleOther 색. core widget `MessageBubble` 활용.
- `2026-05-25`: **페이지네이션 cursor = `created_at`** (keyset). 첫 fetch = LIMIT 50 ORDER BY created_at DESC → 클라에서 역순(ASC) 표시. 추가 fetch = WHERE created_at < <oldest_in_view> LIMIT 50.
- `2026-05-25`: **전송 실패 처리** — 메시지 옆에 ⚠️ 아이콘 + 탭 시 재전송. 실패 메시지는 로컬 상태에만 보관 (DB 반영 X).
- `2026-05-25`: **broadcast 도착 시 chat_room 카드 갱신** — `chatListControllerProvider.invalidateSelf()` 호출. chat_room SPEC에 명시된 hook 패턴.
- `2026-05-25`: **사진/음성 메시지 도착 시** — media_type 검사 → `[사진]` / `[음성]` 텍스트로만 표시. 본 PR scope X. chat_media 머지 시 렌더링 슬롯 추가 예정.
- `2026-05-25`: **메인 빌더 영역 변경 1건** — `mobile/lib/main.dart`의 ProviderScope.overrides에 `chatMessageListSlotProvider.overrideWith(...)` + `chatMessageInputSlotProvider.overrideWith(...)` 2줄 + import 추가. chat_room의 첫 override와 같은 확장 메커니즘.
- `2026-05-27`: **F-026 메시지 수정/삭제 — 시간 제한 없음**. 아이돌이 자기 발행 메시지를 언제든 수정/삭제. 팬은 자기가 보낸 fan_to_idol 메시지를 언제든 수정/삭제. 단순성 우선.
- `2026-05-27`: **삭제 = soft delete** (`deleted_at = NOW()` UPDATE). DB 행 보존. 표시는 "(삭제된 메시지)" placeholder.
- `2026-05-27`: **수정된 메시지 = "(수정됨)" 라벨 작게 표시**. `edited_at != null` 인 메시지에만 시각 옆에 노출. core widget `MessageBubble` 확장 또는 wrapper.
- `2026-05-27`: **Realtime UPDATE 이벤트 구독 추가** — 채팅방 진입 시 INSERT + UPDATE 둘 다 구독. 동일 채널에 두 이벤트 등록. UPDATE 도착 시 controller가 message id 매칭하여 state 교체.

---

## 의문 / 미정 (Open Questions)

1. **메시지 캐싱 정책**
   - 채팅방 진입 시 매번 fetch vs 로컬 캐시 활용?
   - 잠정: 진입마다 최신 50개 fetch + Realtime 구독. 메모리 캐시만. 영속 캐시는 V2.

2. **idol_reply 표시 정책**
   - 아이돌이 다른 팬 메시지에 답장한 경우 — 답장 원본도 같이 표시?
   - 잠정: 답장은 일반 메시지처럼 단독 표시. parent_message_id 본 PR 미사용. chat_meta(F-023)에서 정공.

3. **새 메시지 도착 시 자동 스크롤**
   - 사용자가 위로 스크롤 중인데 새 메시지 도착하면 자동 점프? 또는 "새 메시지 ↓" 인디케이터?
   - 잠정: 가장 아래에 있으면 자동 점프, 위에 있으면 인디케이터 표시.

4. **Realtime 연결 끊김 처리**
   - supabase_flutter가 자동 재연결. 끊김 표시 UI 필요한가?
   - 잠정: 본 PR scope 외. SDK 기본 동작에 위임.

---

## 엣지 케이스 / 메모

- 채팅방 진입 시 응원하지 않는 아이돌 → chat_room이 차단 (본 PR은 진입 받았다고 가정)
- fan_to_idol 메시지 전송 시 RLS 위반 (구독 끊김 등) → ValidationError → 토스트
- Realtime publication 미활성 시 → INSERT는 동작하나 다른 사용자에게 즉시 도착 X. 본인은 optimistic update로 보임. 새로고침으로 fetch 보충.
- 같은 idolId의 두 채팅방 화면 (멀티 인스턴스) — 불가능 (라우터가 단일 라우트).
- 메시지 0개인 새 채팅방 진입 → 빈 상태 placeholder "첫 메시지를 보내보세요"
- 50개 미만으로 끝 → "더 이상 메시지가 없어요" 표시 (또는 silent end)
- 전송 중 화면 이탈 → 임시 메시지 로컬 상태에서 사라짐 (in-flight 취소). 재진입 시 DB fetch가 진실의 원천. 본 PR scope 외 — 단순화.
- 본인이 role=idol — chat_room이 자기 채팅방 진입 차단 (F-024 영역, 본 작업 단위 외)

---

## SPEC.md 로 승격된 항목

- [ ] 슬롯 override (chatMessageListSlot, chatMessageInputSlot)
- [ ] 읽기/쓰기 테이블 (messages 읽기 + INSERT)
- [ ] Realtime 구독 (`messages` INSERT, filter idol_id)
- [ ] 비즈니스 룰 (멱등성, 페이지네이션 cursor, 표시 규칙)

---

## 참고

- 작업 단위 매핑: `docs/FEATURES.md` §2 (#5 메시지 송수신) + §10.4 이슈 #3 분할 권장
- 피처 상세: `docs/FEATURES.md` §3.3
- 의존: `docs/FEATURES.md` §10.1 (chat_message 선행 = chat_room)
- chat_room의 슬롯 인터페이스: `mobile/lib/features/chat_room/SPEC.md`의 `chatMessageListSlotProvider`, `chatMessageInputSlotProvider`
- DB 스키마: `backend/app/shared/models/message.py`, `0001_initial.py`의 messages RLS
- 제품 헌법 §1: 메시지 진실의 원천은 DB. Realtime은 신호 전달용 (best-effort)
- 제품 헌법 §3: 메시지 1개 = DB row 1개. fan-out 시 row 복사 X.
