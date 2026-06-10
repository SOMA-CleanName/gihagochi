/// 가구 1개의 배치 — flame world 좌표(logical) + 표시 폭.
///
/// 백엔드 character_states.furniture_layout {kind: {x, y, w}} 의 값.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'furniture_placement.freezed.dart';
part 'furniture_placement.g.dart';

@freezed
abstract class FurniturePlacement with _$FurniturePlacement {
  const factory FurniturePlacement({
    required double x,
    required double y,
    required double w,
  }) = _FurniturePlacement;

  factory FurniturePlacement.fromJson(Map<String, dynamic> json) =>
      _$FurniturePlacementFromJson(json);
}
