/// 컬러 토큰. Material 3 ColorScheme의 seed 컬러 + 보조 토큰.
///
/// 화면에서 직접 hex 쓰지 말 것. 항상 토큰 경유.
library;

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ──
  static const seedLight = Color(0xFF6750A4);
  static const seedDark = Color(0xFFD0BCFF);

  // ── 상태 ──
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFED6C02);
  static const error = Color(0xFFD32F2F);
  static const info = Color(0xFF0288D1);

  // ── 채팅 버블 ──
  static const bubbleMine = Color(0xFFDCF8C6);
  static const bubbleOther = Color(0xFFEEEEEE);
}
