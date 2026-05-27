/// F-017 / F-018 / F-022 — 채팅방별 메시지 상태.
///
/// `idolId` family. build() 가 첫 페이지 fetch + Realtime 구독을 한꺼번에 처리.
/// optimistic update: pending → DB 확정으로 client_message_id 매칭하여 교체.
/// Realtime 도착 시 chat_room 의 `chatListControllerProvider` invalidate (카드 미리보기 갱신).
library;

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_service.dart';
import '../../chat_meta/data/chat_meta_repository.dart';
import '../../chat_room/application/chat_list_controller.dart';
import '../data/message_repository.dart';
import '../domain/chat_item.dart';
import '../domain/message.dart';
import 'uuid.dart';

part 'chat_messages_controller.g.dart';

@riverpod
class ChatMessagesController extends _$ChatMessagesController {
  RealtimeChannel? _channel;
  bool _hasMore = true;

  @override
  Future<List<ChatItem>> build(String idolId) async {
    final repo = ref.watch(messageRepositoryProvider);
    final supabase = ref.watch(supabaseProvider);
    final me = supabase.auth.currentUser?.id ?? '';

    final messages = await repo.fetchPage(idolId: idolId);
    if (messages.length < pageSize) _hasMore = false;

    _channel = supabase
        .channel('chat_room:$idolId:${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'idol_id',
            value: idolId,
          ),
          callback: (payload) => _onMessageInsert(payload.newRecord, me),
        )
        // F-026 — 다른 기기 / 다른 사용자의 수정·삭제 즉시 반영.
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'idol_id',
            value: idolId,
          ),
          callback: (payload) => _onMessageUpdate(payload.newRecord),
        );
    _channel!.subscribe();

    ref.onDispose(() {
      final ch = _channel;
      if (ch != null) unawaited(supabase.removeChannel(ch));
    });

    // F-021 채팅방 진입 → 읽음 처리. 응원 row 없으면(아이돌이 자기 채팅방) silent 0 row.
    unawaited(ref.read(chatMetaRepositoryProvider).markRoomRead(idolId));

    // 화면에 표시되는 broadcast 메시지에 read 통계 INSERT (멱등).
    for (final m in messages) {
      if (_isBroadcast(m) && m.senderId != me) {
        unawaited(ref.read(chatMetaRepositoryProvider).markBroadcastAsRead(m.id));
      }
    }

    // DESC fetch 결과를 ASC 로 reverse.
    return messages.reversed
        .map<ChatItem>((m) => ConfirmedItem(message: m, isMine: m.senderId == me))
        .toList();
  }

  bool _isBroadcast(Message m) =>
      m.type == MessageType.idolToFans || m.type == MessageType.idolReply;

  bool get hasMore => _hasMore;

  // ── Realtime ───────────────────────────────

  void _onMessageInsert(Map<String, dynamic> raw, String me) {
    final message = Message.fromJson(raw);
    final current = state.value ?? const [];

    // 동일 id 중복 도착 방어 (Realtime 재시도).
    if (current.any((it) => it is ConfirmedItem && it.message.id == message.id)) {
      return;
    }

    // 자기 전송이면 pending 교체. 아니면 append.
    final clientId = message.clientMessageId;
    final pendingIdx = clientId == null
        ? -1
        : current.indexWhere(
            (it) => it is PendingItem && it.clientMessageId == clientId,
          );

    final confirmed = ConfirmedItem(
      message: message,
      isMine: message.senderId == me,
    );

    if (pendingIdx >= 0) {
      final next = List<ChatItem>.of(current)..[pendingIdx] = confirmed;
      state = AsyncValue.data(next);
    } else {
      state = AsyncValue.data([...current, confirmed]);
    }

    // F-021 broadcast 메시지 도착 → 읽음 통계 INSERT (본인 sender 제외, 멱등).
    if (_isBroadcast(message) && message.senderId != me) {
      unawaited(ref.read(chatMetaRepositoryProvider).markBroadcastAsRead(message.id));
    }

    // chat_room 카드 미리보기 갱신 (broadcast hook).
    ref.invalidate(chatListControllerProvider);
  }

  /// F-026 — 다른 곳에서 수정·삭제된 메시지를 즉시 반영.
  /// 동일 message.id 의 ConfirmedItem 을 통째로 교체.
  void _onMessageUpdate(Map<String, dynamic> raw) {
    final updated = Message.fromJson(raw);
    final current = state.value ?? const [];
    final idx = current.indexWhere(
      (it) => it is ConfirmedItem && it.message.id == updated.id,
    );
    if (idx < 0) return;
    final old = current[idx] as ConfirmedItem;
    final next = List<ChatItem>.of(current);
    next[idx] = ConfirmedItem(message: updated, isMine: old.isMine);
    state = AsyncValue.data(next);
    // 카드 미리보기도 갱신 — 마지막 메시지가 수정·삭제됐으면 카드도 영향.
    ref.invalidate(chatListControllerProvider);
  }

  // ── 전송 (F-017) ───────────────────────────

  /// 텍스트 전송. optimistic 즉시 표시 → 성공 시 교체, 실패 시 failed 표시.
  Future<void> sendText(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    final clientId = generateUuidV4();
    final now = DateTime.now().toUtc();
    final pending = PendingItem(
      clientMessageId: clientId,
      idolId: idolId,
      content: trimmed,
      createdAt: now,
    );

    final current = state.value ?? const [];
    state = AsyncValue.data([...current, pending]);

    try {
      final inserted = await _sendByRole(content: trimmed, clientMessageId: clientId);
      _replacePending(clientId, inserted);
    } catch (_) {
      _markFailed(clientId);
      rethrow;
    }
  }

  /// 본인 = idolId면 idol broadcast(type='idol_to_fans', recipient=null),
  /// 아니면 fan_to_idol. RLS 정책 + messages_type_consistency 제약 매칭.
  Future<Message> _sendByRole({
    required String content,
    required String clientMessageId,
  }) {
    final repo = ref.read(messageRepositoryProvider);
    final me = ref.read(supabaseProvider).auth.currentUser?.id;
    if (me != null && me == idolId) {
      return repo.sendIdolBroadcast(content: content, clientMessageId: clientMessageId);
    }
    return repo.sendFanText(
      idolId: idolId,
      content: content,
      clientMessageId: clientMessageId,
    );
  }

  /// 실패한 pending 재전송 — 같은 client_message_id 재사용으로 멱등성 보장.
  Future<void> retry(String clientId) async {
    final current = state.value ?? const [];
    final idx = current.indexWhere(
      (it) => it is PendingItem && it.clientMessageId == clientId,
    );
    if (idx < 0) return;
    final p = current[idx] as PendingItem;

    // 일단 sending 으로 복귀.
    final next = List<ChatItem>.of(current);
    next[idx] = p.copyWith(failed: false);
    state = AsyncValue.data(next);

    try {
      final inserted = await _sendByRole(content: p.content, clientMessageId: clientId);
      _replacePending(clientId, inserted);
    } catch (_) {
      // 중복 / 기타 → 이미 INSERT 됐는지 확인.
      final existing = await ref
          .read(messageRepositoryProvider)
          .findByClientMessageId(clientId);
      if (existing != null) {
        _replacePending(clientId, existing);
      } else {
        _markFailed(clientId);
        rethrow;
      }
    }
  }

  void _replacePending(String clientId, Message msg) {
    final current = state.value ?? const [];
    final idx = current.indexWhere(
      (it) => it is PendingItem && it.clientMessageId == clientId,
    );
    if (idx < 0) return;

    // 같은 db id 가 이미 ConfirmedItem 으로 있으면 pending 만 제거.
    if (current.any((it) => it is ConfirmedItem && it.message.id == msg.id)) {
      final next = List<ChatItem>.of(current)..removeAt(idx);
      state = AsyncValue.data(next);
      return;
    }

    final me = ref.read(supabaseProvider).auth.currentUser?.id ?? '';
    final next = List<ChatItem>.of(current);
    next[idx] = ConfirmedItem(message: msg, isMine: msg.senderId == me);
    state = AsyncValue.data(next);
  }

  void _markFailed(String clientId) {
    final current = state.value ?? const [];
    final idx = current.indexWhere(
      (it) => it is PendingItem && it.clientMessageId == clientId,
    );
    if (idx < 0) return;
    final p = current[idx] as PendingItem;
    final next = List<ChatItem>.of(current);
    next[idx] = p.copyWith(failed: true);
    state = AsyncValue.data(next);
  }

  // ── 페이지네이션 (F-022) ───────────────────

  /// 오래된 메시지 추가 로딩. 가장 오래된 confirmed 의 `created_at` 기준 cursor.
  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.value ?? const [];
    final oldestConfirmed = current.whereType<ConfirmedItem>().cast<ConfirmedItem?>().firstWhere(
          (_) => true,
          orElse: () => null,
        );
    if (oldestConfirmed == null) return;

    final older = await ref.read(messageRepositoryProvider).fetchPage(
          idolId: idolId,
          before: oldestConfirmed.message.createdAt,
        );
    if (older.length < pageSize) _hasMore = false;
    if (older.isEmpty) return;

    final me = ref.read(supabaseProvider).auth.currentUser?.id ?? '';
    final olderItems = older.reversed
        .map<ChatItem>((m) => ConfirmedItem(message: m, isMine: m.senderId == me))
        .toList();
    state = AsyncValue.data([...olderItems, ...current]);
  }

  // ── 수정 / 삭제 (F-026) ─────────────────────

  /// 본인 메시지 본문 수정. RLS 가 sender 검증.
  /// Realtime UPDATE 이벤트가 자체적으로도 발화하지만 즉시 반영 위해 동기 교체.
  Future<void> editMessage({
    required String messageId,
    required String newContent,
  }) async {
    final trimmed = newContent.trim();
    if (trimmed.isEmpty) return;
    final updated = await ref.read(messageRepositoryProvider).updateContent(
          messageId: messageId,
          newContent: trimmed,
        );
    _replaceConfirmed(updated);
  }

  /// 본인 메시지 soft delete. RLS 가 sender 검증.
  Future<void> deleteMessage({required String messageId}) async {
    final updated =
        await ref.read(messageRepositoryProvider).softDelete(messageId: messageId);
    _replaceConfirmed(updated);
  }

  /// 동일 id 의 ConfirmedItem 을 통째로 교체. Realtime UPDATE 와 같은 로직 재사용.
  void _replaceConfirmed(Message updated) {
    final current = state.value ?? const [];
    final idx = current.indexWhere(
      (it) => it is ConfirmedItem && it.message.id == updated.id,
    );
    if (idx < 0) return;
    final old = current[idx] as ConfirmedItem;
    final next = List<ChatItem>.of(current);
    next[idx] = ConfirmedItem(message: updated, isMine: old.isMine);
    state = AsyncValue.data(next);
    ref.invalidate(chatListControllerProvider);
  }
}
