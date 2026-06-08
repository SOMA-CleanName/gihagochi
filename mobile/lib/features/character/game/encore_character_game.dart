/// PR-B 시범용 flame 게임 본체.
///
/// `feature-specs/character.md` v2 "영역 1. Rendering Engine" 결정사항:
/// - logical canvas: 480×800 (도트 게임 저해상도 표준)
/// - filterQuality.none 전제 (도트 그리드 유지 — Sprite 도입 시 적용)
/// - 60fps 게임 루프 (flame 기본)
///
/// 본 PR(PR-B)은 **빈 게임 + GameWidget 임베드 시범까지**.
/// - 캐릭터 Component는 PR-D
/// - 호흡 / 액션 트리거는 PR-E~F
/// - 기존 RoomCanvas Stack 합성 / CharacterPlaceholder 정리는 PR-I
library;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class EncoreCharacterGame extends FlameGame {
  EncoreCharacterGame()
      : super(
          camera: CameraComponent.withFixedResolution(
            width: 480,
            height: 800,
          ),
        );

  /// 방 톤 임시 — 캐릭터/방 에셋 들어오면 SpriteComponent로 교체 (PR-D~).
  @override
  Color backgroundColor() => const Color(0xFF1A0F2E);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // 시범 placeholder — 캔버스 중앙에 작은 네온 사각형.
    // 임베드 검증용. PR-D에서 실제 CharacterComponent로 교체.
    world.add(
      RectangleComponent(
        position: Vector2(240, 400),
        size: Vector2(80, 80),
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFFC770FF),
      ),
    );
  }
}
