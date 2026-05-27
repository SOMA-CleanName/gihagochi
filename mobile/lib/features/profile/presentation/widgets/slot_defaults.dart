/// 다른 피처(chat_room / subscription / notification)가 머지될 때까지
/// MainScreen / 마이페이지의 자리를 메우는 기본 위젯들.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/radius.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';

/// MainScreen 채팅방 리스트 슬롯의 기본 — chat_room 머지 시 override.
///
/// 응원 중 아이돌 0명일 때의 빈 상태 + "아이돌 추가하기" CTA.
class EmptyChatListSlot extends StatelessWidget {
  const EmptyChatListSlot({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_outline,
              size: 56,
              color: AppColors.onSurfaceMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('응원 중인 아이돌이 없어요', style: AppTextStyles.titleLg),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '좋아하는 아이돌을 찾아 응원을 시작해보세요.',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('아이돌 추가하기'),
              onPressed: () => _goDiscover(context),
            ),
          ],
        ),
      ),
    );
  }

  void _goDiscover(BuildContext context) {
    // idol_discovery 머지 전엔 라우트 미존재 → errorBuilder fallback 또는 토스트.
    // 본 PR 범위에선 단순히 `/discover` push 시도.
    try {
      context.push('/discover');
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이돌 탐색은 준비 중입니다.')),
      );
    }
  }
}

/// 마이페이지 "응원 중인 아이돌" 슬롯 기본 — subscription 머지 시 override.
class PlaceholderSubscriptionSlot extends StatelessWidget {
  const PlaceholderSubscriptionSlot({super.key});

  @override
  Widget build(BuildContext context) {
    return _PlaceholderCard(
      icon: Icons.favorite_border,
      title: '응원 중인 아이돌',
      hint: '응원 기능은 곧 추가됩니다.',
    );
  }
}

/// 마이페이지 "알림 설정" 슬롯 기본 — notification 머지 시 override.
class PlaceholderNotificationSlot extends StatelessWidget {
  const PlaceholderNotificationSlot({super.key});

  @override
  Widget build(BuildContext context) {
    return _PlaceholderCard(
      icon: Icons.notifications_none,
      title: '알림 설정',
      hint: '알림 설정은 곧 추가됩니다.',
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({
    required this.icon,
    required this.title,
    required this.hint,
  });

  final IconData icon;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: AppBorderRadius.md,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.onSurfaceMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSm),
                const SizedBox(height: AppSpacing.xs),
                Text(hint, style: AppTextStyles.bodySm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
