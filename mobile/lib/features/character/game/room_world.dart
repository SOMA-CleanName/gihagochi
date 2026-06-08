/// PR-C/D — flame World 골격 + 방 배경 + 캐릭터.
///
/// `feature-specs/character.md` v2:
/// - PR-C: RoomWorld 골격 + 방 배경 SpriteComponent
/// - PR-D: CharacterComponent 추가 (본 파일에서 add)
///
/// 기존 `presentation/widgets/room_background.dart`(PR-1)는 PR-I에서 일괄 정리.
/// 가구(FurnitureComponent)는 PR-H.
library;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'character_component.dart';

/// 방 배경 PNG 원본 사이즈 (853×1844, 9:19).
/// logical viewport(480×800)에 cover-fit으로 폭 480 맞추고 높이는 비율 유지.
/// 결과 높이 = 480 × (1844 / 853) ≈ 1037 → viewport 800보다 큼 → 상하 잘림 (의도).
const double _bgAspect = 1844 / 853;

/// 캐릭터 디스플레이 정책 (PR-D 결정).
/// targetWidth는 logical viewport 480의 62.5% — 방 안 인물로 적절한 비율.
/// position.y는 viewport 하단(+400) 기준 50 위 = 발이 viewport y=350에 위치.
/// 정확한 방 바닥 라인 매칭은 flutter run 검증 후 조정 (Open).
const double _characterWidth = 300;
const double _characterFootY = 350;

class RoomWorld extends World with HasGameReference {
  /// 외부(PR-F)에서 setAction(...) 호출 가능. PR-D는 등장만, 액션 트리거는 PR-F.
  late final CharacterComponent character;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final bgImage = await game.images.load('room_background.png');
    add(
      SpriteComponent(
        sprite: Sprite(bgImage),
        size: Vector2(480, 480 * _bgAspect),
        anchor: Anchor.center,
        position: Vector2.zero(),
        // 도트 아트 보존 — nearest neighbor.
        paint: Paint()..filterQuality = FilterQuality.none,
      ),
    );

    character = CharacterComponent(
      targetWidth: _characterWidth,
      anchor: Anchor.bottomCenter,
      position: Vector2(0, _characterFootY),
    );
    add(character);
  }
}
