/// 앱 전체 배경 — 네온 다크 + 블롭 + 떠다니는 입자 (디자인 시스템 베이스).
///
/// `MaterialApp.builder`에서 모든 화면을 wrap. Scaffold는 transparent라
/// 본 배경이 자동으로 비침.
///
/// 레이어:
///   1. 라디얼 그라데이션 베이스 (살짝 보라 → 검정)
///   2. 정적 네온 블롭 3개 (보라/시안/핑크, 매우 흐릿)
///   3. 떠다니는 입자 35개 (CustomPaint + 20초 cycle loop)
///
/// 성능: RepaintBoundary로 입자만 격리, 베이스/블롭은 const 1회 paint.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/colors.dart';

class AppBackground extends StatefulWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _particles = _initParticles(35);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _GradientBase()),
        const Positioned.fill(child: _Blobs()),
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => CustomPaint(
                painter: _ParticlePainter(_particles, _ctrl.value),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

// ── 레이어 1: 라디얼 그라데이션 베이스 ─────────────

class _GradientBase extends StatelessWidget {
  const _GradientBase();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.3,
          colors: [
            Color(0xFF1A1028), // 위쪽 살짝 보라
            AppColors.background, // #0A0A0F
          ],
          stops: [0.0, 0.75],
        ),
      ),
    );
  }
}

// ── 레이어 2: 네온 블롭 3개 ────────────────────────

class _Blobs extends StatelessWidget {
  const _Blobs();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: -100,
          top: -60,
          child: _blob(AppColors.primary.withValues(alpha: 0.20), 320),
        ),
        Positioned(
          right: -130,
          top: 140,
          child: _blob(AppColors.secondary.withValues(alpha: 0.12), 260),
        ),
        Positioned(
          right: -80,
          bottom: -60,
          child: _blob(AppColors.tertiary.withValues(alpha: 0.14), 280),
        ),
      ],
    );
  }

  Widget _blob(Color color, double size) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 레이어 3: 떠다니는 입자 ────────────────────────

class _Particle {
  const _Particle({
    required this.xSeed,
    required this.ySeed,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.tint,
  });

  final double xSeed;
  final double ySeed;
  final double size;
  final double speed;
  final double opacity;

  /// 0 = white, 1 = primary tint
  final double tint;
}

List<_Particle> _initParticles(int n) {
  final rng = math.Random(42); // 시드 고정 — hot reload 시 위치 안정
  return List.generate(n, (_) {
    return _Particle(
      xSeed: rng.nextDouble(),
      ySeed: rng.nextDouble(),
      size: rng.nextDouble() * 1.4 + 0.6,
      speed: rng.nextDouble() * 0.6 + 0.3,
      opacity: rng.nextDouble() * 0.5 + 0.25,
      tint: rng.nextDouble(),
    );
  });
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.particles, this.t);

  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // y 위치 — 위로 천천히 올라감 (loop). 약간 가로 흔들림.
      final yProgress = (1.0 - ((p.ySeed - t * p.speed) % 1.0));
      final y = yProgress * size.height;
      final xDrift = math.sin((t * 2 * math.pi) + p.xSeed * 6) * 8;
      final x = p.xSeed * size.width + xDrift;

      // 화면 위/아래 가까이는 fade (자연스러운 등장/소멸).
      final fadeY = _fadeAtEdges(yProgress);

      final base = Color.lerp(
        Colors.white,
        AppColors.primary,
        p.tint * 0.7,
      )!;
      final paint = Paint()
        ..color = base.withValues(alpha: p.opacity * fadeY * 0.5);
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  double _fadeAtEdges(double progress) {
    if (progress < 0.1) return progress / 0.1;
    if (progress > 0.9) return (1.0 - progress) / 0.1;
    return 1.0;
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}
