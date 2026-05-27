/// 사용자/아이돌 아바타 — 네온 다크 디자인 시스템 (Phase 2).
///
/// URL 없으면 이니셜 + 그라데이션 배경. `idolRing=true`면 네온 보라 ring.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    this.imageUrl,
    required this.fallbackText,
    this.size = 40,
    this.idolRing = false,
  });

  final String? imageUrl;
  final String fallbackText;
  final double size;

  /// 아이돌 식별 — 네온 보라 ring 1.5px.
  final bool idolRing;

  @override
  Widget build(BuildContext context) {
    final initial =
        fallbackText.isNotEmpty ? fallbackText.characters.first : '?';
    final inner = imageUrl == null || imageUrl!.isEmpty
        ? _fallback(initial)
        : ClipOval(
            child: CachedNetworkImage(
              imageUrl: imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, __) => _fallback(initial),
              errorWidget: (_, __, ___) => _fallback(initial),
            ),
          );

    if (!idolRing) return inner;
    return Container(
      width: size + 4,
      height: size + 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const SweepGradient(
          colors: [
            AppColors.primary,
            AppColors.tertiary,
            AppColors.secondary,
            AppColors.primary,
          ],
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: inner,
    );
  }

  Widget _fallback(String initial) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceContainerHigh,
            AppColors.surfaceContainer,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppTextStyles.titleMd.copyWith(
          fontSize: size * 0.42,
          color: AppColors.onSurfaceVariant,
          fontWeight: AppFontWeight.semiBold,
        ),
      ),
    );
  }
}
