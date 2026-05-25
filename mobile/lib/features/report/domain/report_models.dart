/// F-033 report — freezed 도메인 모델.
///
/// camelDioProvider 사용 (PR #44) → 백엔드 snake_case ↔ 모델 camelCase 자동 변환.
/// `@JsonKey(name:)` 어노테이션 없음.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'report_models.freezed.dart';
part 'report_models.g.dart';

/// reports 단건 응답.
@freezed
abstract class ReportDetail with _$ReportDetail {
  const factory ReportDetail({
    required String id,
    required String reporterId,
    required String messageId,
    required String reason,
    required String status, // 'pending' | 'handled'
    String? resolutionAction, // 'dismissed' | 'message_deleted' | 'warned' | 'suspended'
    String? resolutionNote,
    String? handledBy,
    DateTime? handledAt,
    required DateTime createdAt,
  }) = _ReportDetail;

  factory ReportDetail.fromJson(Map<String, dynamic> json) =>
      _$ReportDetailFromJson(json);
}
