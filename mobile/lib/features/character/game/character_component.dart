/// PR-D — CharacterComponent (Sprite + 액션 PNG 6종 swap).
///
/// `feature-specs/character.md` v2 "PR-D" 범위.
/// 호흡 / 인터랙션 / 백엔드 연동은 PR-E~F.
///
/// PNG 사이즈 정책 (character.md PR-1 디자이너 영역):
/// - idle/happy/sing/eat/sleep: 853×1846 (세로 비율 ~2.164)
/// - sad: 941×1672 (세로 비율 ~1.777, 약간 정사각형에 가까움)
/// → 액션별 PNG 비율로 height 자동 계산해 stretch 방지.
///
/// 디스플레이 정책:
/// - targetWidth: 300 (logical viewport 480의 62.5%)
/// - anchor: Anchor.bottomCenter (캐릭터 발 기준)
/// - position: RoomWorld가 결정 (방 바닥 라인에 맞춤)
library;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../domain/character_action.dart';

class CharacterComponent extends SpriteComponent with HasGameReference {
  CharacterComponent({
    required this.targetWidth,
    super.position,
    super.anchor,
  });

  final double targetWidth;
  CharacterActionType _action = CharacterActionType.idle;
  final Map<CharacterActionType, Sprite> _sprites = {};

  /// PNG 원본 비율 (height / width). 디자이너가 PNG 교체 시 갱신 필요.
  /// sad만 다른 비율 — 같은 width로 stretch 시 늘어나는 문제 방지 (height 별도 계산).
  static const Map<CharacterActionType, double> _aspect = {
    CharacterActionType.idle: 1846 / 853,
    CharacterActionType.happy: 1846 / 853,
    CharacterActionType.sad: 1672 / 941,
    CharacterActionType.sing: 1846 / 853,
    CharacterActionType.eat: 1846 / 853,
    CharacterActionType.sleep: 1846 / 853,
  };

  static const Map<CharacterActionType, String> _file = {
    CharacterActionType.idle: 'character_idle.png',
    CharacterActionType.happy: 'character_happy.png',
    CharacterActionType.sad: 'character_sad.png',
    CharacterActionType.sing: 'character_sing.png',
    CharacterActionType.eat: 'character_eat.png',
    CharacterActionType.sleep: 'character_sleep.png',
  };

  CharacterActionType get currentAction => _action;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 모든 액션 sprite 사전 로드 — swap 시 await 없이 즉시 교체.
    for (final action in CharacterActionType.values) {
      final img = await game.images.load(_file[action]!);
      _sprites[action] = Sprite(img);
    }

    _applyAction(_action);
    // 도트 보존 — character.md v2 "filterQuality.none 전제".
    paint = Paint()..filterQuality = FilterQuality.none;
  }

  /// 액션 전환 — sprite + size 동기 갱신.
  /// PR-F에서 백엔드 state 변경 시 본 메서드 호출.
  void setAction(CharacterActionType next) {
    if (next == _action) return;
    _action = next;
    _applyAction(next);
  }

  void _applyAction(CharacterActionType action) {
    sprite = _sprites[action];
    size = Vector2(targetWidth, targetWidth * _aspect[action]!);
  }
}
