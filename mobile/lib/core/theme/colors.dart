/// 컬러 토큰 — 네온 다크 단일 테마.
///
/// **정책 2026-05-27**: 1차는 네온 다크 한 가지만. 다크 모드 토글 X.
/// 화면에서 직접 hex 쓰지 말 것. 항상 토큰 경유 (`Theme.of(context).colorScheme.xxx`
/// 또는 `AppColors.xxx`).
library;

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── 베이스 surface (다크 그라데이션) ─────────────
  /// 가장 어두운 배경 — Scaffold body.
  static const background = Color(0xFF0A0A0F);

  /// 카드/Sheet — 한 단계 밝음.
  static const surface = Color(0xFF16161D);

  /// 더 밝은 surface (드물게 강조).
  static const surfaceContainer = Color(0xFF1E1E26);
  static const surfaceContainerHigh = Color(0xFF28282F);

  /// 디바이더/아웃라인.
  static const outline = Color(0xFF3A3A45);
  static const outlineVariant = Color(0xFF2A2A33);

  // ── 텍스트 / 아이콘 ─────────────────────────────
  static const onSurface = Color(0xFFF5F5F7);
  static const onSurfaceVariant = Color(0xFFA0A0A8);
  static const onSurfaceMuted = Color(0xFF6E6E78);

  // ── 브랜드 (네온 보라) ──────────────────────────
  /// primary — 네온 마젠타-바이올렛. 버튼/링크/active state.
  static const primary = Color(0xFFC770FF);
  static const primaryHover = Color(0xFFD590FF);
  static const onPrimary = Color(0xFF1A0A2E);
  static const primaryContainer = Color(0xFF3D2A5C);
  static const onPrimaryContainer = Color(0xFFEFD9FF);

  /// secondary — 네온 시안. 보조 강조 / 미디어 컨트롤.
  static const secondary = Color(0xFF00E5FF);
  static const onSecondary = Color(0xFF003845);
  static const secondaryContainer = Color(0xFF003845);
  static const onSecondaryContainer = Color(0xFFB8F4FF);

  /// tertiary — 핫핑크. 선물/응원 등 감성 액션.
  static const tertiary = Color(0xFFFF3DA1);
  static const onTertiary = Color(0xFF3D0017);
  static const tertiaryContainer = Color(0xFF5C1F3D);
  static const onTertiaryContainer = Color(0xFFFFD0E4);

  // ── 시멘틱 ──────────────────────────────────────
  static const success = Color(0xFF22D88F);
  static const warning = Color(0xFFFFB020);
  static const error = Color(0xFFFF5470);
  static const onError = Color(0xFF2A0008);
  static const info = Color(0xFF00B8FF);

  // ── 채팅 버블 ───────────────────────────────────
  /// 내 메시지 — primary tint (네온 보라).
  static const bubbleMine = Color(0xFF3D2A5C);
  static const onBubbleMine = Color(0xFFEFD9FF);

  /// 상대 메시지 — 중간 surface.
  static const bubbleOther = Color(0xFF1E1E26);
  static const onBubbleOther = Color(0xFFF5F5F7);

  // ── 레거시 호환 (출시 후 정리) ──────────────────
  /// @Deprecated. 새 코드는 background/surface 사용.
  static const seedLight = primary;
  static const seedDark = primary;
}

/// Material 3 `ColorScheme` — 네온 다크. 단일 테마, brightness=dark 고정.
const ColorScheme appColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: AppColors.primary,
  onPrimary: AppColors.onPrimary,
  primaryContainer: AppColors.primaryContainer,
  onPrimaryContainer: AppColors.onPrimaryContainer,
  secondary: AppColors.secondary,
  onSecondary: AppColors.onSecondary,
  secondaryContainer: AppColors.secondaryContainer,
  onSecondaryContainer: AppColors.onSecondaryContainer,
  tertiary: AppColors.tertiary,
  onTertiary: AppColors.onTertiary,
  tertiaryContainer: AppColors.tertiaryContainer,
  onTertiaryContainer: AppColors.onTertiaryContainer,
  error: AppColors.error,
  onError: AppColors.onError,
  errorContainer: Color(0xFF5C1F2A),
  onErrorContainer: Color(0xFFFFD9DF),
  surface: AppColors.surface,
  onSurface: AppColors.onSurface,
  onSurfaceVariant: AppColors.onSurfaceVariant,
  surfaceContainerLowest: AppColors.background,
  surfaceContainerLow: Color(0xFF13131A),
  surfaceContainer: AppColors.surfaceContainer,
  surfaceContainerHigh: AppColors.surfaceContainerHigh,
  surfaceContainerHighest: Color(0xFF32323A),
  outline: AppColors.outline,
  outlineVariant: AppColors.outlineVariant,
  shadow: Color(0xFF000000),
  scrim: Color(0xCC000000),
  inverseSurface: AppColors.onSurface,
  onInverseSurface: AppColors.background,
  inversePrimary: Color(0xFF6B3FB8),
);
