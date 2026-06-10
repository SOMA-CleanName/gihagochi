/// F-042 캐릭터 현재 상태 (백엔드 GET /character/{idol_id}/state 응답).
///
/// row 없을 때 백엔드가 default(idle, 100/100/100)으로 채워줌.
//
// freezed 3 + redirected constructor에 @JsonKey 붙이면 invalid_annotation_target
// 경고가 뜨지만 generator는 정상 처리. 알려진 freezed 동작이라 파일 단위로 무시.
// ignore_for_file: invalid_annotation_target
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'character_action.dart';
import 'furniture_placement.dart';

part 'character_state.freezed.dart';
part 'character_state.g.dart';

@freezed
abstract class CharacterState with _$CharacterState {
  const factory CharacterState({
    @JsonKey(name: 'idol_id') required String idolId,
    @JsonKey(name: 'current_action') required CharacterActionType currentAction,
    required int hunger,
    required int happiness,
    required int energy,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    // PR-G2 — 드래그 위치(flame world 좌표). null = 미설정 → 기본 위치 사용.
    @JsonKey(name: 'position_x') double? positionX,
    @JsonKey(name: 'position_y') double? positionY,
    // 가구 배치 {kind: {x,y,w}}. null = 기본 배치(모바일 코드).
    @JsonKey(name: 'furniture_layout') Map<String, FurniturePlacement>? furnitureLayout,
  }) = _CharacterState;

  factory CharacterState.fromJson(Map<String, dynamic> json) =>
      _$CharacterStateFromJson(json);
}
