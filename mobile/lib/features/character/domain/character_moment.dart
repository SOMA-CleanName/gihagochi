/// F-044 — 캐릭터 모먼트 (팬 행동 → 캐릭터 반응).
///
/// 채팅 카드 위쪽에 5초간 떠있다 사라지는 작은 카드.
/// 트리거: 캐릭터 탭(tap), 선물(gift), 사료(feed), 칭찬(praise).
library;

enum CharacterMomentKind { gift, tap, feed, praise }

class CharacterMoment {
  const CharacterMoment({
    required this.kind,
    required this.startedAt,
    this.message,
  });

  final CharacterMomentKind kind;
  final DateTime startedAt;

  /// null이면 kind별 기본 문구 사용.
  final String? message;

  String get displayMessage => message ?? _defaultFor(kind);

  static String _defaultFor(CharacterMomentKind kind) {
    switch (kind) {
      case CharacterMomentKind.gift:
        return '고마워!';
      case CharacterMomentKind.tap:
        return '반가워';
      case CharacterMomentKind.feed:
        return '잘 먹을게';
      case CharacterMomentKind.praise:
        return '함께해서 행복해';
    }
  }
}
