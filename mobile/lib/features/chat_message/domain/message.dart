/// F-017 / F-018 — chat_message 도메인 모델.
///
/// `Message` 는 DB messages row 의 mirror. JSON 직렬화로 Supabase 직결.
/// optimistic 임시 메시지는 application/chat_item.dart 의 sealed 패턴 사용.
//
// freezed 3 + redirected constructor 에 @JsonKey 붙이면 invalid_annotation_target
// 경고가 뜨지만 generator 는 정상 처리.
// ignore_for_file: invalid_annotation_target
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

/// DB enum `message_type` 와 1:1.
enum MessageType {
  @JsonValue('fan_to_idol')
  fanToIdol,
  @JsonValue('idol_to_fans')
  idolToFans,
  @JsonValue('idol_reply')
  idolReply,
}

/// DB enum `media_type` 와 1:1.
enum MediaType {
  @JsonValue('text')
  text,
  @JsonValue('image')
  image,
  @JsonValue('audio')
  audio,
}

/// messages 테이블 row.
@freezed
abstract class Message with _$Message {
  const factory Message({
    required String id,
    @JsonKey(name: 'client_message_id') String? clientMessageId,
    required MessageType type,
    @JsonKey(name: 'sender_id') required String senderId,
    @JsonKey(name: 'idol_id') required String idolId,
    @JsonKey(name: 'recipient_id') String? recipientId,
    @JsonKey(name: 'parent_message_id') String? parentMessageId,
    String? content,
    @JsonKey(name: 'media_type')
    @Default(MediaType.text)
    MediaType mediaType,
    @JsonKey(name: 'media_url') String? mediaUrl,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'edited_at') DateTime? editedAt,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}
