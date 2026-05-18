/// Supabase Realtime — 아이돌 채팅방 토픽 구독 헬퍼.
///
/// 토픽 컨벤션: `idol:<idol_id>` (백엔드 broadcast 트리거와 일치).
/// 권한은 Supabase realtime RLS 정책에서 검증 (구독 가능 여부).
///
/// 라이프사이클:
/// - 화면 진입 시 subscribe
/// - 화면 이탈 시 unsubscribe (Riverpod의 ref.onDispose에서)
/// - 앱 백그라운드 시 supabase_flutter가 자동 처리 (보통 신경 X)
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef BroadcastHandler = void Function(Map<String, dynamic> payload);

class RealtimeService {
  RealtimeService(this._client);

  final SupabaseClient _client;
  final Map<String, RealtimeChannel> _channels = {};

  String idolTopic(String idolId) => 'idol:$idolId';

  /// idol 채팅방 구독. event는 broadcast trigger가 보내는 이벤트명.
  /// 일반적으로 'INSERT' / 'UPDATE' / 'DELETE' (TG_OP).
  RealtimeChannel subscribeToIdol({
    required String idolId,
    required String event,
    required BroadcastHandler onMessage,
  }) {
    final topic = idolTopic(idolId);

    // 이미 구독 중이면 재사용 (중복 채널 방지).
    final existing = _channels[topic];
    if (existing != null) return existing;

    final channel = _client.channel(topic)
      ..onBroadcast(
        event: event,
        callback: (payload) => onMessage(payload),
      )
      ..subscribe((status, error) {
        if (kDebugMode) {
          debugPrint('[Realtime] $topic status=$status error=$error');
        }
      });

    _channels[topic] = channel;
    return channel;
  }

  Future<void> unsubscribe(String topic) async {
    final channel = _channels.remove(topic);
    if (channel != null) {
      await _client.removeChannel(channel);
    }
  }

  Future<void> unsubscribeAll() async {
    for (final channel in _channels.values) {
      await _client.removeChannel(channel);
    }
    _channels.clear();
  }
}
