# F-021 / F-023 chat_meta — 읽음 / 답장 (모바일)

## 개요

채팅방의 읽음 처리(F-021) + 아이돌 답글(F-023). mobile only, Supabase 직결 + RLS, backend 0.

---

## 의존 화면 / 데이터

- **화면 진입 경로**: chat_message의 화면이 mount/액션할 때 본 슬라이스 공개 함수 호출
- **쓰기**: `subscriptions.last_read_at`, `message_reads`, `messages` (idol_reply INSERT)
- **읽기**: 없음 (write only, 화면 표시는 chat_message)
- **Realtime 구독**: 없음 (chat_message가 처리)

---

## 의존 (core)

- `core.auth.auth_service.supabaseProvider` (Supabase 직결)

---

## 비즈니스 룰

1. **읽음 hook**: 채팅방 진입 시 `markRoomRead(idolId)` 호출 → `subscriptions.last_read_at = NOW()` UPDATE (본인 row만, RLS 보호). 응원 안 한 idolId면 row 없으니 0 row affected (silent).
2. **broadcast 읽음 통계**: idol_to_fans/idol_reply 메시지 표시 시 `markBroadcastAsRead(messageId)` 호출 → `message_reads` INSERT. 중복은 PK UNIQUE → 23505 silent.
3. **답장**: `sendIdolReply(parentMessageId, content)` → idol_reply INSERT (sender=idol_id=본인, parent_message_id=fan_to_idol의 id). RLS가 활성 아이돌 + parent가 본인 채팅방의 fan_to_idol인지 검증.
4. **답장 노출**: idol_reply는 broadcast — RLS `messages_select_visible`이 `is_subscribed_to(idol_id)`인 모든 팬에게 노출.

---

## 엣지 케이스

- `markRoomRead`: 응원 row 없으면 UPDATE affected 0. 정상 (예: 아이돌이 자기 채팅방 진입).
- `markBroadcastAsRead`: 중복 INSERT → 23505 catch + ignore.
- `sendIdolReply`: parent 메시지가 본인 채팅방 fan_to_idol 아니면 RLS reject → ValidationError.
- 네트워크 오류: silent log (chat_message UI 차단 X).

---

## 공개 인터페이스 (다른 피처가 호출 가능)

```dart
// data/chat_meta_repository.dart (or split files)

/// 채팅방 진입 시 호출 — 본인의 응원 row의 last_read_at 갱신.
Future<void> markRoomRead(String idolId);

/// broadcast 메시지 표시 시 호출 — message_reads INSERT (멱등).
Future<void> markBroadcastAsRead(String messageId);

/// 아이돌이 fan_to_idol에 답글 — idol_reply INSERT (parent 참조, broadcast 노출).
Future<Message> sendIdolReply({
  required String parentMessageId,
  required String content,
  required String clientMessageId,
});

// presentation/reply_composer_sheet.dart
/// 아이돌이 메시지 롱프레스 시 호출. chat_message가 wire.
Future<void> showReplyComposerSheet(
  BuildContext context, {
  required String parentMessageId,
  String? parentPreviewContent,
});

// routes.dart
List<RouteBase> get chatMetaRoutes; // 빈 리스트 (모달만, 라우트 없음)
```

---

## 수동 테스트 시나리오 (PR 첨부)

1. 팬으로 채팅방 진입 → Supabase `subscriptions.last_read_at` 갱신 확인
2. 팬이 broadcast 메시지 본 후 `message_reads` row 생성 확인 (멱등)
3. 아이돌이 fan_to_idol 메시지 롱프레스 → 답글 모달 → 입력 → 전송 → idol_reply INSERT 확인
4. 답글이 본인 + 응원 중인 모든 팬 화면에 노출 (Realtime broadcast)
5. RLS reject 케이스: 다른 아이돌의 fan_to_idol에 답글 시도 → ValidationError (UI는 그런 경로 노출 X)

기대 결과: 읽음/답글 정상 + RLS가 정책 검증 + broadcast 노출.
