/// 가구 1개의 배치 — flame world 좌표(logical) + 표시 폭 + 편집 조정값.
///
/// 백엔드 character_states.furniture_layout {kind: {x, y, w, bm, dist}} 의 값.
/// bm/dist는 구버전 데이터에 없을 수 있어 nullable — null이면 코드 기본값 유지.
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
    double? bm, // z-order 기준선 비율 (앞/뒤 경계)
    double? dist, // 상호작용 거리 (logical px)
    bool? visible, // 방에 배치 여부 (넣기/빼기)
  }) = _FurniturePlacement;

  factory FurniturePlacement.fromJson(Map<String, dynamic> json) =>
      _$FurniturePlacementFromJson(json);
}
