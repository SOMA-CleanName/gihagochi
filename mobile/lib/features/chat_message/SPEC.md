# F-017 / F-018 / F-022 / F-025 / F-026 메시지 송수신 (chat_message) — 모바일

> 작업 단위 #5 (메시지 송수신). backend SPEC 없음 (모바일 단독, Supabase 직결 + RLS).
> 진화하는 요구사항: [`../../../../feature-specs/chat_message.md`](../../../../feature-specs/chat_message.md)
>
> **§10.4 이슈 #3 분할 진행 현황**:
>   - core PR #41 (머지됨): F-017 / F-018 / F-022
>   - PR #60 (머지됨): F-025 — `sendIdolBroadcast` + role 분기로 사실상 처리
>   - **admin PR (이 SPEC 갱신본의 마지막 단계)**: F-026 수정/삭제
>
> 폴더명: `chat_message`. 라우트 신규 X — `chat_room`의 슬롯 2개를 ProviderScope.overrides로 채움.

---

## 개요

`/chat/:idolId` 채팅방의 메시지 영역(`chatMessageListSlotProvider`)과 입력창(`chatMessageInputSlotProvider`) 슬롯을 chat_message가 채움.
- F-017: 팬→아이돌 텍스트 전송 (RLS가 type/recipient/parent 검증)
- F-018: messages 테이블 INSERT 이벤트 Realtime 구독 → 새 메시지 즉시 도착 (RLS가 가시성 자동 필터)
- F-022: keyset cursor 페이지네이션 (위로 스크롤 → 과거 50개 추가)

본 PR 텍스트 메시지만 — 사진/음성은 chat_media 영역 (`[사진]` / `[음성]` 라벨로 fallback).

관련 화면 / 사용자 / 우선순위: `docs/FEATURES.md` §3.3 (F-017/018/022).

---

## 화면 (Routes)

본 PR은 **신규 라우트 0개**. chat_room의 `/chat/:idolId` 안에서 슬롯만 채움.

- `chatMessageListSlotProvider(idolId)` → `MessageList(idolId)` widget
- `chatMessageInputSlotProvider(idolId)` → `MessageInput(idolId)` widget

main.dart의 ProviderScope.overrides에 2줄 추가:

```dart
chatMessageListSlotProvider(<dynamic>).overrideWith((ref, idolId) => MessageList(idolId: idolId)),
chatMessageInputSlotProvider(<dynamic>).overrideWith((ref, idolId) => MessageInput(idolId: idolId)),
```

(family Provider의 override 정확한 문법은 riverpod 3 기준 — 구현 시 검증)

---

## 의존 화면 / 데이터

- **화면 진입 경로**: chat_room의 `/chat/:idolId` 진입 → 본 슬롯 위젯들이 자동 렌더링
- **읽기 (Supabase 직결, RLS 보호)**:
  - `messages` (idol_id=X) — SELECT page 50개, ORDER BY created_at DESC
  - RLS `messages_select_visible` 가 자동 필터: 본인 sender + idol_to_fans/idol_reply(구독자) + fan_to_idol(아이돌만 본인 + 본인 fan)
- **쓰기 (Supabase 직결)**:
  - `messages` INSERT — type=fan_to_idol (팬) 또는 idol_to_fans (본인=idol_id 일 때 broadcast)
  - client_message_id = UUID v4 (멱등성)
  - RLS `messages_insert_fan` / `messages_insert_idol` 가 type/recipient 검증
  - **F-026 수정/삭제**: `messages` UPDATE — 본인 메시지만. RLS `messages_update_self` 가 `sender_id == me AND deleted_at IS NULL` 강제. soft delete = `deleted_at = NOW()` UPDATE.
- **Realtime 구독**:
  - 채널: `public:messages:idol_id=eq.<idolId>`
  - 이벤트: **INSERT + UPDATE** (F-026 후 UPDATE 추가)
  - 채팅방 진입 시 subscribe, 이탈 시 unsubscribe
- **백엔드 API**: 없음
- **Storage**: 없음 (텍스트만)

> **사전 적용 (dev DB)**: `ALTER PUBLICATION supabase_realtime ADD TABLE messages;` 실행 완료. 재현용 알렘빅 migration은 후속 `infra/realtime-publication` PR로 캡처 예정.

---

## 의존 (core)

- `core.auth.auth_service.supabaseProvider` — Supabase 직결
- `core.widgets.message_bubble.MessageBubble` — 본인/상대 말풍선 (isMine 분기 + 색 + 시각)
- `core.widgets.{loading_view, error_view, empty_view, app_text_field}` — 공용
- features/chat_room의 슬롯 Provider: `chatMessageListSlotProvider`, `chatMessageInputSlotProvider` (override 대상)
- features/chat_room의 `chatListControllerProvider` — broadcast 도착 시 invalidate (카드 갱신 hook)
- features/gift `showGiftComingSoonSheet(context, idolId)` — 입력창 좌측 선물 버튼 호출 대상 (F-027)
- features/character `triggerGiftMomentForIdol(ref, idolId)` — gift sheet close 후 캐릭터 위 모먼트 카드 트리거 (F-044 연계). 본인=아이돌이면 호출 X (자기 자신에게 선물 X).

> **메인 빌더 영역 변경 (본 PR 동봉, 사전 승인)**:
> 1. `mobile/lib/main.dart` — ProviderScope.overrides에 2줄 + import 추가 (chat_room이 첫 사례 만든 패턴 연장)
> 2. DB 영역 (별도 PR로 캡처 예정) — `ALTER PUBLICATION supabase_realtime ADD TABLE messages;` dev 적용 완료

---

## 비즈니스 룰

- 메시지 정렬: `created_at` ASC (오래된 위, 최신 아래). 채팅방 진입 시 자동 스크롤 최하단.
- 본인 메시지(`sender_id == me`) = 오른쪽 정렬 + bubbleMine. 아이돌 메시지(idol_to_fans/idol_reply, 즉 sender_id == idol_id) = 왼쪽 + bubbleOther.
- 전송 흐름:
  1. 입력창 텍스트 + 전송 → `client_message_id = uuid.v4()`
  2. **optimistic update**: 로컬 메시지 리스트에 임시 메시지 (`status=sending`) 추가 → 즉시 화면 반영
  3. Supabase INSERT (client_message_id 포함)
  4. 성공: 임시 메시지를 DB row로 교체 (Realtime이 자체 INSERT 이벤트도 발화 — 중복 방지 위해 client_message_id 또는 메시지 id로 dedupe)
  5. 실패(RLS / 네트워크): 임시 메시지 `status=failed` + ⚠️ 아이콘 + 탭으로 재전송 (같은 client_message_id 재사용 → DB unique partial index가 중복 차단)
- 페이지네이션:
  - 초기: LIMIT 50 ORDER BY created_at DESC → 클라에서 reverse하여 ASC 표시
  - 추가: WHERE created_at < <oldest_in_view> LIMIT 50
  - 반환 50개 미만 → "더 이상 메시지가 없어요" (또는 silent end). 추가 fetch 비활성화.
- Realtime 도착 시:
  - 자기 sender_id의 INSERT (자기 전송) → 이미 optimistic으로 표시됨. 임시 메시지 → DB row로 교체 (client_message_id 매칭).
  - 다른 sender_id INSERT (아이돌 broadcast) → 리스트 아래에 append + 사용자가 최하단에 있으면 자동 스크롤, 아니면 "새 메시지 ↓" 인디케이터.
  - 모든 INSERT 도착 시 → `chatListControllerProvider.invalidateSelf()` 호출해서 chat_room 카드 미리보기 갱신.
- 사진/음성 메시지 (media_type='photo'/'voice') 도착 시 → chat_media 위젯 슬롯이 렌더링 (PR #62~64).
- 채팅방 이탈 (route pop, dispose) → Realtime 구독 해제. Provider auto-dispose 패턴 활용.

### F-026 메시지 수정/삭제 (admin PR)

- **수정 트리거**: 본인 메시지 (`sender_id == auth.uid()`) 롱프레스 → ActionSheet "메시지 수정" → 다이얼로그 (기존 content prefill, 멀티라인) → 저장 → `messages` UPDATE (`content = <new>`, `edited_at = NOW()`).
- **삭제 트리거**: 본인 메시지 롱프레스 → "메시지 삭제" → 확인 모달 ("정말 삭제하시겠습니까?") → `messages` UPDATE (`deleted_at = NOW()`).
- **시간 제한 없음** — 사용자 결정. 본인 메시지면 언제든 수정/삭제.
- **수정된 메시지 표시** — `edited_at != null` 인 메시지는 시각 옆에 "(수정됨)" 작은 라벨.
- **삭제된 메시지 표시** — 본문을 "(삭제된 메시지)" placeholder 로 교체 (core PR 에서 이미 처리).
- **Realtime UPDATE 도착 시** — 동일 message id 매칭 → ConfirmedItem 의 message 교체. UI 자동 재렌더링.
- **다른 사람 메시지 롱프레스 시** — ActionSheet 액션 비활성 (자기 메시지가 아니면 "메시지 수정" / "메시지 삭제" 표시 X). 기존 chat_meta 의 메뉴 옵션은 그대로 살림.

---

## 엣지 케이스

- **메시지 0개** → 빈 상태 "첫 메시지를 보내보세요" + 입력창은 정상 활성화
- **fan_to_idol INSERT RLS 거부** (구독 끊김 등) → PostgrestException → 임시 메시지 status=failed + 토스트
- **Realtime 미연결** → 자기 INSERT는 optimistic으로 보이고 DB 반영 OK. 다른 사용자 메시지는 새로고침으로 보충 (pull-to-refresh 본 PR 미포함 — 추가 검토)
- **client_message_id 중복** (재전송) → DB unique partial index → PostgrestException(23505) catch → 이미 성공한 것으로 간주, 임시 메시지를 DB row로 교체
- **빠른 연속 전송** (1초에 5개) — optimistic은 즉시, INSERT는 비동기. UI는 sending 상태 그대로 표시.
- **매우 긴 메시지** — DB는 text 타입(무제한). UI에서 적당히 wrap. 입력 길이 제한 별도 X (V2).
- **상대(아이돌) suspended 상태에서 메시지 수신** → 이전에 받은 메시지는 그대로 표시. 새 INSERT는 아이돌의 messages_insert_idol RLS의 `is_active_idol`이 차단 → 새 메시지 안 옴.
- **본인 deleted_at != null** (탈퇴 직후 라이브 세션) → RLS가 모든 INSERT 차단. 사용자는 auth_guard에 의해 곧 logout.
- **페이지네이션 중 새 메시지 도착** → 추가 fetch는 오래된 쪽이라 무관. append만 발생.
- **route pop 후 메시지 도착** → 구독 해제됐으므로 이벤트 못 받음. 다음 채팅방 진입 시 fresh fetch로 동기화.

### F-026 엣지 케이스

- **수정 중 메시지가 다른 곳에서 삭제됨** (이론상 본인이 다른 기기로) → UPDATE Realtime이 도착해서 (삭제된 메시지)로 갱신. 수정 다이얼로그는 그대로 열려 있다가 저장 시 RLS의 `deleted_at IS NULL` 조건이 0 row 매칭으로 silent fail 또는 PostgrestException. 토스트 후 닫기.
- **삭제 후 즉시 같은 자리에 다시 메시지 INSERT** — DB row는 별개 (id 다름). 정상 동작.
- **이미 삭제된 메시지 다시 삭제 시도** — RLS의 `deleted_at IS NULL` 조건이 0 row 매칭 → silent. UI는 이미 (삭제된 메시지) 표시 중이라 차이 없음.
- **수정된 본문이 공백/빈 문자열** → 클라이언트 측에서 차단 (trim() 후 빈 문자열이면 저장 비활성).

---

## 공개 인터페이스 (다른 피처가 호출 가능)

```dart
// features/chat_message/presentation/message_list.dart
//
// chat_room 슬롯 override 대상. main.dart의 ProviderScope에서 등록.
class MessageList extends ConsumerStatefulWidget {
  const MessageList({super.key, required this.idolId});
  final String idolId;
}

// features/chat_message/presentation/message_input.dart
//
// chat_room 슬롯 override 대상.
class MessageInput extends ConsumerStatefulWidget {
  const MessageInput({super.key, required this.idolId});
  final String idolId;
}

// features/chat_message/application/message_send_controller.dart
//
// 후속 chat_message_admin PR(F-025 아이돌 발행)이 재사용할 가능성. 일단 internal.
```

> 위에 없는 함수/위젯은 internal. 후속 admin PR에서 필요 시 SPEC 갱신.

---

## 수동 테스트 시나리오 (PR 첨부)

> **사전 조건**: chat_room mock seed 적용 상태 (idolA/B + subscription + 메시지 2개). Realtime publication 활성화 완료.

### 시나리오 1: 메시지 리스트 표시
1. `/main` → idolA 카드 탭 → `/chat/<idolA_id>` 진입
2. 기존 메시지 ("hi from idol A") 가 왼쪽 정렬 bubbleOther로 표시
3. 시간(HH:mm) 함께 표시
4. 자동 스크롤 최하단

### 시나리오 2: 텍스트 전송 (optimistic update)
1. 입력창에 "안녕!" 입력 → 전송
2. 즉시 오른쪽 정렬 bubbleMine으로 표시 (status=sending)
3. INSERT 성공 → 정상 메시지로 교체
4. dev DB 확인: messages 테이블에 1행 INSERT 완료

### 시나리오 3: Realtime 수신
1. 채팅방 진입 상태 유지
2. 다른 터미널에서 SQL: `INSERT INTO messages (type, sender_id, idol_id, content, media_type) VALUES ('idol_to_fans', '<idolA_id>', '<idolA_id>', '실시간 테스트', 'text');`
3. 앱 화면에 메시지 자동 도착 → 왼쪽 정렬 bubbleOther로 append
4. /main 으로 뒤로가기 → idolA 카드 미리보기가 "실시간 테스트"로 갱신됨

### 시나리오 4: 페이지네이션
1. dev DB에 메시지 60개 일괄 INSERT
2. 채팅방 진입 → 최신 50개 표시
3. 위로 스크롤 → 추가 10개 fetch → 표시
4. 다시 위로 → 0개 fetch → "더 이상 메시지가 없어요" 표시 (또는 silent end)

### 시나리오 5: 전송 실패 + 재시도
1. 입력창 텍스트 → 전송 직전에 dev DB에서 subscription 강제 unsubscribed
2. 전송 → RLS 거부 → ⚠️ + 토스트
3. unsubscribed 복구 후 ⚠️ 탭 → 재전송 → 성공

### 시나리오 6: 미디어 메시지 fallback
1. dev DB에 `INSERT INTO messages (type, sender_id, idol_id, media_type, media_url) VALUES ('idol_to_fans', '<idolA_id>', '<idolA_id>', 'image', 'http://...');`
2. 채팅방에 "[사진]" 라벨로 표시 (실제 이미지 미렌더 — chat_media 영역)
