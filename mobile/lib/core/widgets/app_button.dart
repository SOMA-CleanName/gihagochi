/// 표준 액션 버튼 — 네온 다크 디자인 시스템 (Phase 2).
///
/// variant: primary(네온 보라) / secondary(시안) / tertiary(핑크) / outline / text
/// size: lg(48) / md(40) / sm(32)
/// glow: 네온 그림자 효과 (강조 액션)
library;

import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/radius.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

enum AppButtonVariant { primary, secondary, tertiary, outline, text }

enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.lg,
    this.isLoading = false,
    this.icon,
    this.glow = false,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final bool glow;
  final bool fullWidth;

  double get _height => switch (size) {
        AppButtonSize.sm => 32,
        AppButtonSize.md => 40,
        AppButtonSize.lg => 48,
      };

  TextStyle get _textStyle => switch (size) {
        AppButtonSize.sm => AppTextStyles.labelMd,
        AppButtonSize.md => AppTextStyles.labelLg,
        AppButtonSize.lg => AppTextStyles.labelLg,
      };

  ({Color bg, Color fg, Color? border}) get _palette => switch (variant) {
        AppButtonVariant.primary => (
            bg: AppColors.primary,
            fg: AppColors.onPrimary,
            border: null,
          ),
        AppButtonVariant.secondary => (
            bg: AppColors.secondary,
            fg: AppColors.onSecondary,
            border: null,
          ),
        AppButtonVariant.tertiary => (
            bg: AppColors.tertiary,
            fg: AppColors.onTertiary,
            border: null,
          ),
        AppButtonVariant.outline => (
            bg: Colors.transparent,
            fg: AppColors.primary,
            border: AppColors.outline,
          ),
        AppButtonVariant.text => (
            bg: Colors.transparent,
            fg: AppColors.primary,
            border: null,
          ),
      };

  Color? get _glowColor {
    if (!glow) return null;
    return switch (variant) {
      AppButtonVariant.primary => AppColors.primary,
      AppButtonVariant.secondary => AppColors.secondary,
      AppButtonVariant.tertiary => AppColors.tertiary,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette;
    final disabled = onPressed == null || isLoading;
    final child = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: p.fg,
            ),
          )
        : Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: p.fg),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                label,
                style: _textStyle.copyWith(
                  color: p.fg,
                  fontWeight: AppFontWeight.semiBold,
                ),
              ),
            ],
          );

    final button = Material(
      color: disabled ? p.bg.withValues(alpha: 0.4) : p.bg,
      borderRadius: AppBorderRadius.sm,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: AppBorderRadius.sm,
        child: Container(
          height: _height,
          padding: EdgeInsets.symmetric(
            horizontal: size == AppButtonSize.sm
                ? AppSpacing.md
                : AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            borderRadius: AppBorderRadius.sm,
            border: p.border != null
                ? Border.all(color: p.border!, width: 1)
                : null,
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );

    final wrapped = _glowColor != null && !disabled
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppBorderRadius.sm,
              boxShadow: [
                BoxShadow(
                  color: _glowColor!.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: button,
          )
        : button;

    return fullWidth ? SizedBox(width: double.infinity, child: wrapped) : wrapped;
  }
}
