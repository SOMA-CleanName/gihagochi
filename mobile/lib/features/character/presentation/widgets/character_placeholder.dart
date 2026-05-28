/// F-040 정적 캐릭터 — 에셋 폴백.
///
/// 실제 캐릭터 PNG가 들어오면 본 위젯을 교체.
/// 1차 폴백: 라운드 실루엣 + "캐릭터 준비 중" 라벨.
/// 캐릭터는 채팅 카드 위쪽 영역에 center-bottom 정렬.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';

class CharacterPlaceholder extends StatelessWidget {
  const CharacterPlaceholder({super.key, required this.idolId});

  final String idolId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 캐릭터 자리 — 라운드 그라데이션 실루엣.
          Container(
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
