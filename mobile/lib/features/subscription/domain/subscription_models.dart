/// F-012 / F-013 subscription — freezed 모델.
///
/// 빌드: `dart run build_runner build` (또는 watch)
library;

// freezed factory parameter에 @JsonKey 부착은 analyzer가 invalid_annotation_target
// warning을 띄우지만 codegen은 정상 동작 — 백엔드 snake_case 매핑 의도.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_models.freezed.dart';
part 'subscription_models.g.dart';

/// 백엔드 Pydantic이 snake_case로 직렬화하므로 @JsonKey로 명시 매핑.
@freezed
abstract class SubscriptionDetail with _$SubscriptionDetail {
  const factory SubscriptionDetail({
    @JsonKey(name: 'fan_id') required String fanId,
    @JsonKey(name: 'idol_id') required String idolId,
    @JsonKey(name: 'subscribed_at') required DateTime subscribedAt,
    @JsonKey(name: 'unsubscribed_at') DateTime? unsubscribedAt,
    @JsonKey(name: 'last_read_at') required DateTime lastReadAt,
    @JsonKey(name: 'is_active') required bool isActive,
  }) = _SubscriptionDetail;

  factory SubscriptionDetail.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionDetailFromJson(json);
}
