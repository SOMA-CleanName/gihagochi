/// F-040 정적 캐릭터 — 실제 PNG 에셋 6종 + 탭 순환 데모.
///
/// PR-1 후속: placeholder 실루엣 → 6종 캐릭터 PNG 교체.
/// 6종 PNG는 모두 480×800 캔버스, 같은 좌표에 띄우면 같은 위치에서 표정만 바뀜.
///
/// 탭 시:
///   - sparkle scale 애니메이션
///   - haptic feedback (lightImpact)
///   - 데모 토글: 6종 순환 (idle → happy → sad → sing → eat → sleep → idle)
///     → PR-2에서 백엔드 상태 도입 시 토글 제거 예정
///   - characterMomentControllerProvider에 tap moment dispatch
///   - 디바운스 500ms
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../../application/character_moment_controller.dart';
import '../../domain/character_action.dart';
import '../../domain/character_moment.dart';

/// 캐릭터 표시 크기 = 화면 폭의 이 비율.
const double characterWidthRatio = 0.5;

/// 캐릭터 PNG 캔버스 비율 (852×1846 ≈ 1:2.166).
/// sad만 다른 비율(941×1672)이지만 BoxFit.contain으로 SizedBox 안에서 자동 비율 유지.
const double _characterCanvasAspect = 1846 / 852;

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

  CharacterActionType _action = CharacterActionType.idle;

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
    setState(() => _action = _action.next);
    ref
        .read(characterMomentControllerProvider(widget.idolId).notifier)
        .show(CharacterMomentKind.tap);
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final width = screenW * characterWidthRatio;
    final height = width * _characterCanvasAspect;

    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedBuilder(
          animation: _sparkle,
          builder: (context, child) {
            final t = _sparkle.value;
            final scale = 1.0 + 0.06 * (t < 0.5 ? t * 2 : (1 - t) * 2);
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
          child: SizedBox(
            width: width,
            height: height,
            child: Image.asset(
              _action.assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none, // 픽셀 아트
              gaplessPlayback: true, // 토글 시 깜빡임 방지
            ),
          ),
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
