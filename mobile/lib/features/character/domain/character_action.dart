/// F-040 / F-043 — 캐릭터 행동 타입.
///
/// 6종: idle / happy / sad / sing / eat / sleep.
/// 같은 캔버스(480×800)에 그려진 PNG 6장. 같은 좌표에 띄우면 같은 자리에서 자연스럽게 표정만 바뀜.
///
/// 이름은 백엔드 `character_action_type` enum과 1:1 동기 — **이름 변경 X**.
library;

import 'package:json_annotation/json_annotation.dart';

enum CharacterActionType {
  @JsonValue('idle')
  idle,
  @JsonValue('happy')
  happy,
  @JsonValue('sad')
  sad,
  @JsonValue('sing')
  sing,
  @JsonValue('eat')
  eat,
  @JsonValue('sleep')
  sleep,
}

extension CharacterActionAsset on CharacterActionType {
  String get assetPath {
    switch (this) {
      case CharacterActionType.idle:
        return 'assets/character/character_idle.png';
      case CharacterActionType.happy:
        return 'assets/character/character_happy.png';
      case CharacterActionType.sad:
        return 'assets/character/character_sad.png';
      case CharacterActionType.sing:
        return 'assets/character/character_sing.png';
      case CharacterActionType.eat:
        return 'assets/character/character_eat.png';
      case CharacterActionType.sleep:
        return 'assets/character/character_sleep.png';
    }
  }

  /// 데모 토글용 — 다음 순환 값. PR-2 백엔드 도입 후 제거 예정.
  CharacterActionType get next {
    final all = CharacterActionType.values;
    final i = all.indexOf(this);
    return all[(i + 1) % all.length];
  }
}
