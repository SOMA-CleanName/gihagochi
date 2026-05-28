/// F-039 방 배경 — 에셋 폴백.
///
/// 실제 PNG 에셋이 들어오면 이 위젯을 교체. 1차 폴백:
/// - 다크 퍼플 라디얼 그라데이션 (top-center spotlight)
/// - 미세 grid 도트 (도트 픽셀 톤)
/// - 바닥 ground 라인 (캐릭터 자리 강조)
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';

class RoomBackground extends StatelessWidget {
  const RoomBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 라디얼 그라데이션 — top center에 약한 spotlight.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.5),
                radius: 1.1,
                colors: [
                  Color(0xFF231040), // 보라 spotlight
                  Color(0xFF12091E), // 다크 베이스
                ],
                stops: [0.0, 0.85],
              ),
            ),
          ),
        ),
        // 도트 grid 패턴.
        const Positioned.fill(
          child: CustomPaint(painter: _DotGridPainter()),
        ),
        // 하단 바닥 라인 (캐릭터가 서있을 위치).
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  AppColors.primary.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  static const double _step = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.onSurfaceVariant.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    for (double y = _step; y < size.height; y += _step) {
      for (double x = _step; x < size.width; x += _step) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) => false;
}
