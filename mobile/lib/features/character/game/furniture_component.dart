/// PR-H — 가구 컴포넌트 (sprite 기반).
///
/// `feature-specs/character.md` v2 "PR-H".
/// 위치 기반 상호작용:
/// - RoomWorld가 매 frame 캐릭터 ↔ 각 가구 거리 측정
/// - 임계값 이내 도달 시 actionWhenNear 트리거 (CharacterComponent.setAction)
library;

import 'package:flame/components.dart';

import '../domain/character_action.dart';
import 'encore_character_game.dart';

enum FurnitureKind { bed, desk, chair, standmic, mirror }

class FurnitureComponent extends SpriteComponent
    with HasGameReference<EncoreCharacterGame> {
  FurnitureComponent({
    required this.kind,
    required this.actionWhenNear,
    required this.assetFile,
    required this.targetWidth,
    this.bottomMargin = 0,
    super.position,
    super.anchor,
  });

  /// 가구 종류.
  final FurnitureKind kind;

  /// 캐릭터가 본 가구 근처에 도달했을 때 트리거할 액션.
  final CharacterActionType actionWhenNear;

  /// 에셋 파일명 (assets/character/ 기준).
  final String assetFile;

  /// 화면 표시 폭 (logical). height는 PNG 원본 비율로 자동.
  double targetWidth;

  /// PNG 바닥 여백 비율 (불투명 영역이 PNG 맨 아래보다 위에 있는 정도).
  /// z-order 기준선(시각적 바닥) 계산에 사용. anchor center 전제.
  final double bottomMargin;

  /// z-order/근접 판정의 기준이 되는 시각적 바닥 y (world 좌표).
  /// anchor center → position.y + size.y/2 가 PNG 바닥, 여백만큼 위로 보정.
  double get baseY => position.y + size.y * (0.5 - bottomMargin);

  @override
  Future<void> onLoad() async {
    final img = await game.images.load(assetFile);
    sprite = Sprite(img);
    size = Vector2(targetWidth, targetWidth * img.height / img.width);
    _syncPriority();
  }

  /// 바닥선 y를 priority로 — 캐릭터(priority=발y)와 y-sort 되어 앞뒤 자동 결정.
  void _syncPriority() {
    priority = baseY.round();
  }
}
