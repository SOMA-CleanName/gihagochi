/// 그림자 / elevation 토큰.
///
/// 네온 다크는 그림자 약함 — Material 3 surface tonal로 대체.
/// 강조 필요 시 네온 glow (primary tint) 사용.
library;

import 'package:flutter/material.dart';

import 'colors.dart';

class AppElevation {
  AppElevation._();

  static const double none = 0;
  static const double sm = 1;
  static const double md = 3;
  static const double lg = 6;
  static const double xl = 12;
}

/// 자주 쓰는 BoxShadow — 다크 베이스에 맞춰 alpha 낮게.
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x4D000000),
      blurRadius: 12,
      offset: Offset(0, 3),
    ),
  ];

  /// 네온 글로우 (primary). 강조 컴포넌트.
  static const List<BoxShadow> neonPrimary = [
    BoxShadow(
      color: Color(0x66C770FF),
      blurRadius: 20,
      offset: Offset(0, 0),
    ),
  ];

  static const List<BoxShadow> neonSecondary = [
    BoxShadow(
      color: Color(0x6600E5FF),
      blurRadius: 20,
      offset: Offset(0, 0),
    ),
  ];
}

/// 강조 컴포넌트 호환 helper. ([Container.decoration].
BoxDecoration neonGlow({Color color = AppColors.primary, double radius = 12}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20),
    ],
  );
}
