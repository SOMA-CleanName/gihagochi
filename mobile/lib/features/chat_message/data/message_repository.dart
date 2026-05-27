/// F-017 / F-018 / F-022 — messages 테이블 직결.
///
/// 모두 Supabase. 백엔드 API 없음. RLS 가 권한 통제.
/// Realtime 구독은 호출자 (controller) 가 채널 lifecycle 직접 관리.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/error/app_error.dart';
import '../domain/message.dart';

part 'message_repository.g.dart';

const pageSize = 50;

@riverpod
MessageRepository messageRepository(Ref ref) {
  return MessageRepository(supabase: ref.watch(supabaseProvider));
}

class MessageRepository {
  MessageRepository({required this.supabase});

  final SupabaseClient supabase;

  String get _userId {
    final id = supabase.auth.currentUser?.id;
    if (id == null) {
      throw const UnauthorizedError(message: '로그인이 필요합니다.');
    }
    return id;
  }

  // ── 페이지 fetch (F-022) ────────────────────

  /// `idolId` 의 메시지 최신 `pageSize` 개 — DESC 정렬.
  /// `before` 가 있으면 `created_at < before` 로 cursor pagination.
  /// 반환은 호출자가 reverse 해서 ASC 로 표시.
  Future<List<Message>> fetchPage({
    required String idolId,
    DateTime? before,
  }) async {
    var query = supabase.from('messages').select().eq('idol_id', idolId);
    if (before != null) {
      query = query.lt('created_at', before.toUtc().toIso8601String());
    }
    final rows = await query
        .order('created_at', ascending: false)
        .limit(pageSize);
    return rows.map((r) => Message.fromJson(r)).toList();
  }

  // ── 전송 (F-017) ───────────────────────────

  /// 팬→아이돌 텍스트 메시지 INSERT. `clientMessageId` 는 멱등성용.
  /// 성공 시 INSERT 된 row 반환. RLS 위반 / 중복 client_message_id 면 throw.
  Future<Message> sendFanText({
    required String idolId,
    required String content,
    required String clientMessageId,
  }) async {
    final userId = _userId;
    try {
      final row = await supabase
          .from('messages')
          .insert({
            'client_message_id': clientMessageId,
            'type': 'fan_to_idol',
            'sender_id': userId,
            'idol_id': idolId,
            'recipient_id': idolId,
            'content': content,
            'media_type': 'text',
          })
          .select()
          .single();
      return Message.fromJson(row);
    } on PostgrestException catch (e) {
      // 23505 = unique violation (재전송 중복 client_message_id).
      // 이 경우 호출자가 "이미 성공한 것" 으로 간주하고 fetchByClientId 로 보충 가능.
      if (e.code == '23505') {
        throw ValidationError(
          message: '메시지가 이미 전송되었습니다.',
          cause: e,
        );
      }
      throw ValidationError(
        message: '메시지 전송에 실패했습니다. (${e.message})',
        cause: e,
      );
    }
  }

  /// 아이돌→팬들 broadcast 텍스트 메시지 INSERT. F-024.
  /// type='idol_to_fans', recipient_id=NULL (broadcast — 모든 응원 팬 대상).
  /// `messages_type_consistency` 제약과 매칭.
  Future<Message> sendIdolBroadcast({
    required String content,
    required String clientMessageId,
  }) async {
    final userId = _userId; // 아이돌 본인 = sender = idol_id
    try {
      final row = await supabase
          .from('messages')
          .insert({
            'client_message_id': clientMessageId,
            'type': 'idol_to_fans',
            'sender_id': userId,
            'idol_id': userId,
            // recipient_id: 명시 X (NULL — broadcast)
            'content': content,
            'media_type': 'text',
          })
          .select()
          .single();
      return Message.fromJson(row);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw ValidationError(message: '메시지가 이미 전송되었습니다.', cause: e);
      }
      throw ValidationError(
        message: '메시지 전송에 실패했습니다. (${e.message})',
        cause: e,
      );
    }
  }

  /// 중복 INSERT 시 / 재전송 시 기존 row 조회.
  Future<Message?> findByClientMessageId(String clientMessageId) async {
    final userId = _userId;
    final row = await supabase
        .from('messages')
        .select()
        .eq('sender_id', userId)
        .eq('client_message_id', clientMessageId)
        .maybeSingle();
    return row == null ? null : Message.fromJson(row);
  }

  // ── 수정 / 삭제 (F-026) ─────────────────────

  /// 본인 메시지 본문 수정. `edited_at = NOW()` 표시 (수정됨 라벨용).
  /// RLS `messages_update_self` 가 sender_id/deleted_at 검증.
  /// 시간 제한 없음 — 본인 메시지면 언제든.
  Future<Message> updateContent({
    required String messageId,
    required String newContent,
  }) async {
    final userId = _userId;
    try {
      final row = await supabase
          .from('messages')
          .update({
            'content': newContent,
            'edited_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', messageId)
          .eq('sender_id', userId)
          .select()
          .single();
      return Message.fromJson(row);
    } on PostgrestException catch (e) {
      throw ValidationError(
        message: '메시지 수정에 실패했습니다. (${e.message})',
        cause: e,
      );
    }
  }

  /// 본인 메시지 soft delete. `deleted_at = NOW()` UPDATE.
  /// DB row 보존 — 표시는 "(삭제된 메시지)" placeholder.
  Future<Message> softDelete({required String messageId}) async {
    final userId = _userId;
    try {
      final row = await supabase
          .from('messages')
          .update({
            'deleted_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', messageId)
          .eq('sender_id', userId)
          .select()
          .single();
      return Message.fromJson(row);
    } on PostgrestException catch (e) {
      throw ValidationError(
        message: '메시지 삭제에 실패했습니다. (${e.message})',
        cause: e,
      );
    }
  }
}
