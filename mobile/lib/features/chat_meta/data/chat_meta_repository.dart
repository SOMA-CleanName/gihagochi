/// F-021 / F-023 chat_meta — Supabase 직결 (backend API 없음).
///
/// - `markRoomRead`: subscriptions.last_read_at UPDATE
/// - `markBroadcastAsRead`: message_reads INSERT (멱등)
/// - `sendIdolReply`: messages INSERT (type='idol_reply', parent_message_id)
library;

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/error/app_error.dart';
import '../../chat_message/domain/message.dart';
import '../domain/fan_reply.dart';

part 'chat_meta_repository.g.dart';

@riverpod
ChatMetaRepository chatMetaRepository(Ref ref) {
  return ChatMetaRepository(supabase: ref.watch(supabaseProvider));
}

class ChatMetaRepository {
  ChatMetaRepository({required this.supabase});

  final SupabaseClient supabase;

  String get _userId {
    final id = supabase.auth.currentUser?.id;
    if (id == null) {
      throw const UnauthorizedError(message: '로그인이 필요합니다.');
    }
    return id;
  }

  // ── F-021 읽음 ────────────────────────────

  /// 채팅방 진입 시 호출. 본인 subscription row의 last_read_at = NOW().
  /// row 없으면(아이돌이 자기 채팅방 진입 등) silent 0 row affected.
  Future<void> markRoomRead(String idolId) async {
    final userId = _userId;
    try {
      await supabase
          .from('subscriptions')
          .update({'last_read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('fan_id', userId)
          .eq('idol_id', idolId);
    } catch (e) {
      // 진입 흐름 차단 X — silent log.
      if (kDebugMode) debugPrint('[chat_meta] markRoomRead 실패: $e');
    }
  }

  /// broadcast 메시지(idol_to_fans/idol_reply) 표시 시 호출.
  /// PK(message_id, fan_id) UNIQUE라 중복 INSERT 시 23505 → silent ignore.
  Future<void> markBroadcastAsRead(String messageId) async {
    final userId = _userId;
    try {
      await supabase.from('message_reads').insert({
        'message_id': messageId,
        'fan_id': userId,
      });
    } on PostgrestException catch (e) {
      // 23505 = unique violation — 이미 읽음 처리됨, 멱등 OK.
      if (e.code == '23505') return;
      if (kDebugMode) debugPrint('[chat_meta] markBroadcastAsRead 실패: $e');
    }
  }

  // ── 아이돌 답장 보기 ─────────────────────

  /// 아이돌 본인의 broadcast 사이 구간에 들어온 fan_to_idol 메시지 조회.
  /// `fromCreatedAt`(exclusive) ~ `toCreatedAt`(exclusive, null이면 NOW).
  /// sender profile (display_name)을 JOIN해서 함께 반환 — 답장 보기 화면이 닉네임 표시.
  Future<List<FanReply>> fetchFanRepliesBetween({
    required String idolId,
    required DateTime fromCreatedAt,
    DateTime? toCreatedAt,
  }) async {
    var query = supabase
        .from('messages')
        .select('*, sender:sender_id(id, display_name)')
        .eq('idol_id', idolId)
        .eq('type', 'fan_to_idol')
        .gt('created_at', fromCreatedAt.toUtc().toIso8601String());
    if (toCreatedAt != null) {
      query = query.lt('created_at', toCreatedAt.toUtc().toIso8601String());
    }
    final rows = await query.order('created_at', ascending: true);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(FanReply.fromJson)
        .toList(growable: false);
  }

  // ── F-023 답장 ───────────────────────────

  /// 아이돌이 fan_to_idol에 답글. type='idol_reply', parent_message_id 채움.
  /// RLS `messages_insert_idol`이 활성 아이돌 + parent가 본인 채팅방의 fan_to_idol 검증.
  Future<Message> sendIdolReply({
    required String parentMessageId,
    required String content,
    required String clientMessageId,
  }) async {
    final userId = _userId; // 아이돌 본인 = sender = idol_id
    try {
      final row = await supabase
          .from('messages')
          .insert({
            'client_message_id': clientMessageId,
            'type': 'idol_reply',
            'sender_id': userId,
            'idol_id': userId,
            // recipient_id: NULL (broadcast — 모든 응원 팬에게 노출)
            'parent_message_id': parentMessageId,
            'content': content,
            'media_type': 'text',
          })
          .select()
          .single();
      return Message.fromJson(row);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw ValidationError(message: '답글이 이미 전송되었습니다.', cause: e);
      }
      throw ValidationError(
        message: '답글 전송에 실패했습니다. (${e.message})',
        cause: e,
      );
    }
  }
}
