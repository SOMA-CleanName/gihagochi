/// F-040 정적 캐릭터 — 에셋 폴백 + F-044 탭 반응.
///
/// 실제 캐릭터 PNG가 들어오면 본 위젯을 교체.
/// 1차 폴백: 라운드 실루엣 + "캐릭터 준비 중" 라벨.
/// 캐릭터는 채팅 카드 위쪽 영역에 center-bottom 정렬.
///
/// 탭 시:
///   - sparkle scale 애니메이션
///   - haptic feedback (lightImpact)
///   - characterMomentControllerProvider에 tap moment dispatch
///   - 디바운스 500ms (sparkle 중 재탭 무시)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../application/character_moment_controller.dart';
import '../../domain/character_moment.dart';

class CharacterPlaceholder extends ConsumerStatefulWidget {
  const CharacterPlaceholder({super.key, required this.idolId});

  final String idolId;

  @override
  ConsumerState<CharacterPlaceholder> createState() =>
      _CharacterPlaceholderState();
}

class _CharacterPlaceholderState extends ConsumerState<CharacterPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sparkle;
  DateTime _lastTapAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _tapDebounce = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _sparkle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _sparkle.dispose();
    super.dispose();
  }

  void _onTap() {
    final now = DateTime.now();
    if (now.difference(_lastTapAt) < _tapDebounce) return;
    _lastTapAt = now;

    HapticFeedback.lightImpact();
    _sparkle.forward(from: 0);
    ref
        .read(characterMomentControllerProvider(widget.idolId).notifier)
        .show(CharacterMomentKind.tap);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: _onTap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedBuilder(
              animation: _sparkle,
              builder: (context, child) {
                final t = _sparkle.value;
                final scale = 1.0 + 0.08 * (t < 0.5 ? t * 2 : (1 - t) * 2);
                return Transform.scale(
                  scale: scale,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      child!,
                      if (t > 0) _SparkleOverlay(t: t),
                    ],
                  ),
                );
              },
              child: _CharacterSilhouette(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '캐릭터 준비 중',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterSilhouette extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(70),
          bottom: Radius.circular(20),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.25),
            AppColors.tertiary.withValues(alpha: 0.18),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 40,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.person_outline,
          size: 64,
          color: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _SparkleOverlay extends StatelessWidget {
  const _SparkleOverlay({required this.t});

  /// 0.0 ~ 1.0 진행도.
  final double t;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (final spec in _sparkPositions)
              Positioned(
                left: 100 + spec.$1 * (40 + 30 * t),
                top: 80 + spec.$2 * (40 + 30 * t),
                child: Opacity(
                  opacity: (1 - t).clamp(0.0, 1.0),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 14 + 4 * t,
                    color: AppColors.secondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static const List<(double, double)> _sparkPositions = [
    (-1.0, -0.3),
    (1.0, -0.5),
    (-0.6, 0.7),
    (0.7, 0.6),
    (0.0, -1.0),
  ];
}
