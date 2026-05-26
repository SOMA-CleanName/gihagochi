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
        );
    _channel!.subscribe();

    ref.onDispose(() {
      final ch = _channel;
      if (ch != null) unawaited(supabase.removeChannel(ch));
    });

    // DESC fetch 결과를 ASC 로 reverse.
    return messages.reversed
        .map<ChatItem>((m) => ConfirmedItem(message: m, isMine: m.senderId == me))
        .toList();
  }

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

    // chat_room 카드 미리보기 갱신 (broadcast hook).
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
      final inserted = await ref.read(messageRepositoryProvider).sendFanText(
            idolId: idolId,
            content: trimmed,
            clientMessageId: clientId,
          );
      _replacePending(clientId, inserted);
    } catch (_) {
      _markFailed(clientId);
      rethrow;
    }
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
      final inserted = await ref.read(messageRepositoryProvider).sendFanText(
            idolId: idolId,
            content: p.content,
            clientMessageId: clientId,
          );
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
}
