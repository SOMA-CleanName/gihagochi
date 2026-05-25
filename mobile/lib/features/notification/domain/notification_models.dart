/// F-029 / F-031 notification — freezed 도메인 모델.
///
/// 빌드: `dart run build_runner build` (또는 watch)
library;

// freezed factory parameter에 @JsonKey 부착은 analyzer warning이지만
// 백엔드 snake_case 매핑 의도. (idol_models, subscription_models 동일 패턴)
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_models.freezed.dart';
part 'notification_models.g.dart';

/// GET / PATCH /notification/prefs 응답.
@freezed
abstract class NotificationPrefs with _$NotificationPrefs {
  const factory NotificationPrefs({
    @JsonKey(name: 'new_message_enabled') required bool newMessageEnabled,
    @JsonKey(name: 'idol_reply_enabled') required bool idolReplyEnabled,
    @JsonKey(name: 'marketing_enabled') required bool marketingEnabled,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _NotificationPrefs;

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) =>
      _$NotificationPrefsFromJson(json);
}

/// PATCH /notification/prefs 요청 — 부분 업데이트.
/// repository에서 toJson 사용 시 null 필드는 자동 제외 (includeIfNull: false).
@freezed
abstract class NotificationPrefsPatch with _$NotificationPrefsPatch {
  const factory NotificationPrefsPatch({
    @JsonKey(name: 'new_message_enabled', includeIfNull: false) bool? newMessageEnabled,
    @JsonKey(name: 'idol_reply_enabled', includeIfNull: false) bool? idolReplyEnabled,
    @JsonKey(name: 'marketing_enabled', includeIfNull: false) bool? marketingEnabled,
  }) = _NotificationPrefsPatch;

  factory NotificationPrefsPatch.fromJson(Map<String, dynamic> json) =>
      _$NotificationPrefsPatchFromJson(json);
}

/// POST /notification/device-tokens 응답 (참고용 — repository는 void 반환).
@freezed
abstract class DeviceTokenResponse with _$DeviceTokenResponse {
  const factory DeviceTokenResponse({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String platform,
    required String token,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'last_used_at') required DateTime lastUsedAt,
  }) = _DeviceTokenResponse;

  factory DeviceTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$DeviceTokenResponseFromJson(json);
}
