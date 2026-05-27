/// 답장 보기 화면용 — fan_to_idol 메시지 + sender 프로필 일부.
///
/// chat_message의 Message와 별도. read-only + sender display_name 동반.
library;

class FanReplySender {
  const FanReplySender({required this.id, required this.displayName});

  final String id;
  final String displayName;

  factory FanReplySender.fromJson(Map<String, dynamic> json) {
    return FanReplySender(
      id: json['id'] as String,
      displayName: (json['display_name'] as String?) ?? '익명',
    );
  }
}

class FanReply {
  const FanReply({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.sender,
  });

  final String id;
  final String? content;
  final DateTime createdAt;
  final FanReplySender sender;

  factory FanReply.fromJson(Map<String, dynamic> json) {
    final senderRaw = json['sender'];
    return FanReply(
      id: json['id'] as String,
      content: json['content'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      sender: senderRaw is Map<String, dynamic>
          ? FanReplySender.fromJson(senderRaw)
          : FanReplySender(
              id: (json['sender_id'] as String?) ?? '',
              displayName: '익명',
            ),
    );
  }
}
