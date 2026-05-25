/// F-008 ~ F-011 idol_discovery — freezed 도메인 모델.
///
/// 빌드: `dart run build_runner build` (또는 watch)
/// → `idol_models.freezed.dart` + `idol_models.g.dart` 생성됨.
library;

// freezed factory parameter에 @JsonKey 부착은 analyzer가 invalid_annotation_target
// warning을 띄우지만 codegen은 정상 동작 — 백엔드 snake_case 매핑 의도.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'idol_models.freezed.dart';
part 'idol_models.g.dart';

/// 탐색 리스트의 카드 1개. GET /idols 응답 items.
/// 백엔드 Pydantic이 snake_case로 직렬화하므로 @JsonKey로 명시 매핑.
@freezed
abstract class IdolListItem with _$IdolListItem {
  const factory IdolListItem({
    required String id,
    @JsonKey(name: 'stage_name') required String stageName,
    @JsonKey(name: 'bio_summary') String? bioSummary,
    @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
    @JsonKey(name: 'activated_at') required DateTime activatedAt,
  }) = _IdolListItem;

  factory IdolListItem.fromJson(Map<String, dynamic> json) =>
      _$IdolListItemFromJson(json);
}

/// GET /idols 응답.
@freezed
abstract class IdolListPage with _$IdolListPage {
  const factory IdolListPage({
    required List<IdolListItem> items,
    required int page,
    @JsonKey(name: 'page_size') required int pageSize,
    @JsonKey(name: 'has_more') required bool hasMore,
  }) = _IdolListPage;

  factory IdolListPage.fromJson(Map<String, dynamic> json) =>
      _$IdolListPageFromJson(json);
}

/// 상세 화면. GET /idols/{id} 응답.
@freezed
abstract class IdolDetail with _$IdolDetail {
  const factory IdolDetail({
    required String id,
    @JsonKey(name: 'stage_name') required String stageName,
    String? bio,
    @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
    @JsonKey(name: 'activated_at') required DateTime activatedAt,
    @JsonKey(name: 'fan_count') required int fanCount,
    @JsonKey(name: 'is_subscribed') required bool isSubscribed,
  }) = _IdolDetail;

  factory IdolDetail.fromJson(Map<String, dynamic> json) =>
      _$IdolDetailFromJson(json);
}
