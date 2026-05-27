/// F-031 — 마이페이지 "알림 설정" 슬롯에 끼우는 진입 카드.
///
/// `profile`의 `notificationSettingsSlotProvider`를 main.dart에서 override해
/// 본 위젯을 끼움. tap → `/settings/notifications`.
///
/// 디자인은 `profile/.../slot_defaults.dart`의 `PlaceholderNotificationSlot`과
/// 동일한 카드 형태 + chevron (눌러서 진입 가능 표시).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';

class NotificationSettingsEntry extends StatelessWidget {
  const NotificationSettingsEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainer,
      borderRadius: AppBorderRadius.md,
      child: InkWell(
        borderRadius: AppBorderRadius.md,
        onTap: () => context.push('/settings/notifications'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: const [
              Icon(Icons.notifications_none, color: AppColors.onSurfaceVariant),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('알림 설정', style: AppTextStyles.titleSm),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      '푸시 알림 / 메시지 / 마케팅 알림 관리',
                      style: AppTextStyles.bodySm,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.onSurfaceMuted),
            ],
          ),
        ),
      ),
    );
  }
}
