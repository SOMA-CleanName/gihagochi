/// F-012 / F-013 subscription — freezed 모델.
///
/// 빌드: `dart run build_runner build` (또는 watch)
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_models.freezed.dart';
part 'subscription_models.g.dart';

@freezed
abstract class SubscriptionDetail with _$SubscriptionDetail {
  const factory SubscriptionDetail({
    required String fanId,
    required String idolId,
    required DateTime subscribedAt,
    DateTime? unsubscribedAt,
    required DateTime lastReadAt,
    required bool isActive,
  }) = _SubscriptionDetail;

  factory SubscriptionDetail.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionDetailFromJson(json);
}
