/// 텍스트 스타일 토큰 — Pretendard 기반.
///
/// 정책 2026-05-27: 한국어 표준 폰트 Pretendard 사용. 실제 폰트 자산 등록은
/// 별도 PR (pubspec.yaml + assets/fonts) — 본 PR은 fontFamily 'Pretendard' 명시만.
/// 미등록 시 OS 기본(SF/Roboto)로 fallback.
library;

import 'package:flutter/material.dart';

import 'colors.dart';

const String _font = 'Pretendard';

class AppFontWeight {
  AppFontWeight._();

  static const thin = FontWeight.w100;
  static const extraLight = FontWeight.w200;
  static const light = FontWeight.w300;
  static const regular = FontWeight.w400;
  static const medium = FontWeight.w500;
  static const semiBold = FontWeight.w600;
  static const bold = FontWeight.w700;
  static const extraBold = FontWeight.w800;
  static const black = FontWeight.w900;
}

/// Material 3 textTheme 위에 토큰 스타일.
class AppTextStyles {
  AppTextStyles._();

  // ── Display (브랜드 / 거의 안 씀) ──────────────
  static const display = TextStyle(
    fontFamily: _font,
    fontSize: 32,
    fontWeight: AppFontWeight.extraBold,
    height: 1.2,
    color: AppColors.onSurface,
  );

  // ── Headline ─────────────────────────────────
  static const headlineLg = TextStyle(
    fontFamily: _font,
    fontSize: 24,
    fontWeight: AppFontWeight.bold,
    height: 1.25,
    color: AppColors.onSurface,
  );

  static const headlineMd = TextStyle(
    fontFamily: _font,
    fontSize: 20,
    fontWeight: AppFontWeight.bold,
    height: 1.3,
    color: AppColors.onSurface,
  );

  // ── Title ─────────────────────────────────────
  static const titleLg = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    fontWeight: AppFontWeight.semiBold,
    height: 1.35,
    color: AppColors.onSurface,
  );

  static const titleMd = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: AppFontWeight.semiBold,
    height: 1.4,
    color: AppColors.onSurface,
  );

  static const titleSm = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: AppFontWeight.semiBold,
    height: 1.4,
    color: AppColors.onSurface,
  );

  // ── Body ──────────────────────────────────────
  static const bodyLg = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: AppFontWeight.regular,
    height: 1.5,
    color: AppColors.onSurface,
  );

  static const bodyMd = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: AppFontWeight.regular,
    height: 1.5,
    color: AppColors.onSurface,
  );

  static const bodySm = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: AppFontWeight.regular,
    height: 1.45,
    color: AppColors.onSurfaceVariant,
  );

  // ── Label (버튼/탭/뱃지) ──────────────────────
  static const labelLg = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: AppFontWeight.semiBold,
    height: 1.3,
    color: AppColors.onSurface,
  );

  static const labelMd = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: AppFontWeight.medium,
    height: 1.3,
    color: AppColors.onSurfaceVariant,
  );

  static const labelSm = TextStyle(
    fontFamily: _font,
    fontSize: 11,
    fontWeight: AppFontWeight.medium,
    height: 1.2,
    color: AppColors.onSurfaceVariant,
  );

  // ── 채팅 컨텍스트 (조정) ──────────────────────
  static const messageBody = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: AppFontWeight.regular,
    height: 1.45,
  );

  static const messageTimestamp = TextStyle(
    fontFamily: _font,
    fontSize: 11,
    fontWeight: AppFontWeight.regular,
    color: AppColors.onSurfaceMuted,
  );

  // ── 레거시 호환 ──────────────────────────────
  /// @Deprecated — 새 코드는 bodySm 사용.
  static const emptyHint = bodySm;
}

/// `ThemeData.textTheme` 으로 주입할 Material 3 TextTheme.
const TextTheme appTextTheme = TextTheme(
  displayLarge: AppTextStyles.display,
  displayMedium: AppTextStyles.display,
  displaySmall: AppTextStyles.headlineLg,
  headlineLarge: AppTextStyles.headlineLg,
  headlineMedium: AppTextStyles.headlineMd,
  headlineSmall: AppTextStyles.titleLg,
  titleLarge: AppTextStyles.titleLg,
  titleMedium: AppTextStyles.titleMd,
  titleSmall: AppTextStyles.titleSm,
  bodyLarge: AppTextStyles.bodyLg,
  bodyMedium: AppTextStyles.bodyMd,
  bodySmall: AppTextStyles.bodySm,
  labelLarge: AppTextStyles.labelLg,
  labelMedium: AppTextStyles.labelMd,
  labelSmall: AppTextStyles.labelSm,
);
