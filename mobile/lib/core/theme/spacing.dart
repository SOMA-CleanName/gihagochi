/// 공간 토큰 — 4 기반 grid.
///
/// `Padding(padding: EdgeInsets.all(AppSpacing.md))` 패턴 권장.
/// 화면에서 매직넘버 쓰지 말 것.
library;

class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
  static const double massive = 64;
}

/// 컴포넌트 높이 표준.
class AppHeight {
  AppHeight._();

  /// 표준 버튼 높이 — 터치 타겟 최소 44 보장.
  static const double button = 48;
  static const double buttonSm = 36;

  /// 입력 필드.
  static const double textField = 48;

  /// AppBar (커스텀 시).
  static const double appBar = 56;

  /// BottomNav.
  static const double bottomNav = 64;

  /// ListTile leading icon container.
  static const double listAvatar = 56;
}
