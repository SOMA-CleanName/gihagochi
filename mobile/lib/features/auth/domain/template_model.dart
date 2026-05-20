/// F-XXX 도메인 모델 (freezed).
///
/// 빌드: `dart run build_runner build` (또는 watch)
/// → `template_model.freezed.dart` + `template_model.g.dart` 생성됨.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'template_model.freezed.dart';
part 'template_model.g.dart';

@freezed
abstract class TemplateItem with _$TemplateItem {
  const factory TemplateItem({
    required String id,
    required String title,
    String? description,
    required DateTime createdAt,
  }) = _TemplateItem;

  factory TemplateItem.fromJson(Map<String, dynamic> json) =>
      _$TemplateItemFromJson(json);
}
