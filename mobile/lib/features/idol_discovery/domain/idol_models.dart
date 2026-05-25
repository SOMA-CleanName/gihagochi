/// F-008 ~ F-011 idol_discovery — freezed 도메인 모델.
///
/// 빌드: `dart run build_runner build` (또는 watch)
/// → `idol_models.freezed.dart` + `idol_models.g.dart` 생성됨.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'idol_models.freezed.dart';
part 'idol_models.g.dart';

/// 탐색 리스트의 카드 1개. GET /idols 응답 items.
@freezed
abstract class IdolListItem with _$IdolListItem {
  const factory IdolListItem({
    required String id,
    required String stageName,
    String? bioSummary,
    String? thumbnailUrl,
    required DateTime activatedAt,
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
    required int pageSize,
    required bool hasMore,
  }) = _IdolListPage;

  factory IdolListPage.fromJson(Map<String, dynamic> json) =>
      _$IdolListPageFromJson(json);
}

/// 상세 화면. GET /idols/{id} 응답.
@freezed
abstract class IdolDetail with _$IdolDetail {
  const factory IdolDetail({
    required String id,
    required String stageName,
    String? bio,
    String? thumbnailUrl,
    required DateTime activatedAt,
    required int fanCount,
    required bool isSubscribed,
  }) = _IdolDetail;

  factory IdolDetail.fromJson(Map<String, dynamic> json) =>
      _$IdolDetailFromJson(json);
}
