/// UI 가 표시하는 채팅 아이템 — DB 확정 메시지(Message) + 로컬 optimistic 임시.
///
/// 같은 리스트에서 둘 다 렌더링하기 위해 sealed 패턴 사용. freezed 안 씀 —
/// 비교/JSON 직렬화 불필요한 UI-only 상태라 plain Dart 가 충분.
library;

import 'message.dart';

sealed class ChatItem {
  /// ListView key — 안정적으로 유일.
  String get key;
  DateTime get createdAt;
  bool get isMine;
}

/// DB 에서 fetch/Realtime 으로 도착한 확정 메시지.
class ConfirmedItem extends ChatItem {
  ConfirmedItem({required this.message, required this.isMine});

  final Message message;
  @override
  final bool isMine;

  @override
  String get key => message.id;

  @override
  DateTime get createdAt => message.createdAt;
}

/// 로컬 optimistic 임시 — INSERT in-flight 또는 실패.
class PendingItem extends ChatItem {
  PendingItem({
    required this.clientMessageId,
    required this.idolId,
    required this.content,
    required this.createdAt,
    this.failed = false,
  });

  final String clientMessageId;
  final String idolId;
  final String content;
  @override
  final DateTime createdAt;

  /// `true` 면 ⚠️ 표시 + 탭으로 재전송.
  final bool failed;

  @override
  String get key => 'pending:$clientMessageId';

  /// pending = 항상 본인 메시지 (전송 중).
  @override
  bool get isMine => true;

  PendingItem copyWith({bool? failed}) => PendingItem(
        clientMessageId: clientMessageId,
        idolId: idolId,
        content: content,
        createdAt: createdAt,
        failed: failed ?? this.failed,
      );
}
