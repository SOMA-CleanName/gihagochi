/// F-040 정적 캐릭터 + F-041 호흡 애니메이션 — 백엔드 state 기반.
///
/// state 출처: characterStateControllerProvider(idolId)
///   - 백엔드 GET /character/{idol_id}/state (row 없으면 default idle)
///
/// 애니메이션 (F-041, Flutter implicit only — Rive/flame 미사용):
///   - 호흡 scale (±1.8%, easeInOut, 2.8s 왕복). 액션별 duration:
///       sleep 4.2s / eat 3.4s / sing 2.2s / 그 외 2.8s
///   - 액션 변경 시 PNG 페이드 전환 280ms (AnimatedSwitcher)
///
/// 탭 시:
///   - sparkle scale 애니메이션 + haptic
///   - 다음 순환 action을 백엔드 POST → 응답으로 state 즉시 갱신
///   - characterMomentControllerProvider에 tap moment dispatch
///   - 디바운스 500ms (sparkle 중 재탭 무시)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../../application/character_moment_controller.dart';
import '../../application/character_state_controller.dart';
import '../../domain/character_action.dart';
import '../../domain/character_moment.dart';

const double characterWidthRatio = 0.5;
const double _characterCanvasAspect = 1846 / 852;

class CharacterPlaceholder extends ConsumerStatefulWidget {
  const CharacterPlaceholder({super.key, required this.idolId});

  final String idolId;

  @override
  ConsumerState<CharacterPlaceholder> createState() =>
      _CharacterPlaceholderState();
}

class _CharacterPlaceholderState extends ConsumerState<CharacterPlaceholder>
    with TickerProviderStateMixin {
  late final AnimationController _sparkle;
  late final AnimationController _breathe;
  DateTime _lastTapAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _tapDebounce = Duration(milliseconds: 500);

  /// 호흡 scale 범위 (±). 너무 크면 부자연스러움.
  static const double _breatheAmplitude = 0.018;

  @override
  void initState() {
    super.initState();
    _sparkle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sparkle.dispose();
    _breathe.dispose();
    super.dispose();
  }

  /// 액션별 호흡 duration — 자거나 먹을 땐 더 느리게.
  Duration _breatheDurationFor(CharacterActionType action) {
    switch (action) {
      case CharacterActionType.sleep:
        return const Duration(milliseconds: 4200);
      case CharacterActionType.eat:
        return const Duration(milliseconds: 3400);
      case CharacterActionType.sing:
        return const Duration(milliseconds: 2200);
      default:
        return const Duration(milliseconds: 2800);
    }
  }

  Future<void> _onTap(CharacterActionType current) async {
    final now = DateTime.now();
    if (now.difference(_lastTapAt) < _tapDebounce) return;
    _lastTapAt = now;

    HapticFeedback.lightImpact();
    _sparkle.forward(from: 0);
    ref
        .read(characterMomentControllerProvider(widget.idolId).notifier)
        .show(CharacterMomentKind.tap);

    // 탭은 순환 액션 트리거 — PR-2 데모 동작 유지 (실 비즈니스 룰은 후속 PR).
    try {
      await ref
          .read(characterStateControllerProvider(widget.idolId).notifier)
          .trigger(current.next);
    } catch (_) {
      // 백엔드 실패해도 sparkle/모먼트는 이미 진행. silent.
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final width = screenW * characterWidthRatio;
    final height = width * _characterCanvasAspect;

    final stateAsync = ref.watch(characterStateControllerProvider(widget.idolId));
    final action = stateAsync.maybeWhen(
      data: (s) => s.currentAction,
      orElse: () => CharacterActionType.idle, // loading/error → default 표시
    );

    // 액션 바뀔 때 호흡 속도 조정 (자기/먹기 천천히, 노래 빠르게).
    final breatheDuration = _breatheDurationFor(action);
    if (_breathe.duration != breatheDuration) {
      _breathe.duration = breatheDuration;
    }

    return GestureDetector(
      onTap: () => _onTap(action),
      behavior: HitTestBehavior.opaque,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedBuilder(
          animation: Listenable.merge([_sparkle, _breathe]),
          builder: (context, child) {
            final tap = _sparkle.value;
            final tapScale = 1.0 + 0.06 * (tap < 0.5 ? tap * 2 : (1 - tap) * 2);
            // _breathe.value는 [0,1] 왕복. ease 적용해 부드러운 sin-like 곡선.
            final breatheCurve = Curves.easeInOut.transform(_breathe.value);
            final breatheScale = 1.0 + _breatheAmplitude * breatheCurve;
            return Transform.scale(
              scale: tapScale * breatheScale,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  child!,
                  if (tap > 0) _SparkleOverlay(t: tap),
                ],
              ),
            );
          },
          child: SizedBox(
            width: width,
            height: height,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: Image.asset(
                action.assetPath,
                key: ValueKey(action),
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                gaplessPlayback: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SparkleOverlay extends StatelessWidget {
  const _SparkleOverlay({required this.t});

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
