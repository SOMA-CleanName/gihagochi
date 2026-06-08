/// PR-C — flame World 골격 + 방 배경 SpriteComponent.
///
/// `feature-specs/character.md` v2 "PR-C" 범위.
/// 기존 `presentation/widgets/room_background.dart`(PR-1)는 PR-I에서 일괄 정리.
/// 본 PR은 RoomWorld 골격만 + 방 배경 1장. 캐릭터/가구는 PR-D~H.
library;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// 방 배경 PNG 원본 사이즈 (853×1844, 9:19).
/// logical viewport(480×800)에 cover-fit으로 폭 480 맞추고 높이는 비율 유지.
/// 결과 높이 = 480 × (1844 / 853) ≈ 1037 → viewport 800보다 큼 → 상하 잘림 (의도).
const double _bgAspect = 1844 / 853;

class RoomWorld extends World with HasGameReference {
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final image = await game.images.load('room_background.png');
    final sprite = Sprite(image);

    add(
      SpriteComponent(
        sprite: sprite,
        size: Vector2(480, 480 * _bgAspect),
        anchor: Anchor.center,
        position: Vector2.zero(),
        // 도트 아트 보존 — nearest neighbor.
        paint: Paint()..filterQuality = FilterQuality.none,
      ),
    );
  }
}
