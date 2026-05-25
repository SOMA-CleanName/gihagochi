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

class NotificationSettingsEntry extends StatelessWidget {
  const NotificationSettingsEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/settings/notifications'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.notifications_none, color: Color(0xFF616161)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('알림 설정', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      '푸시 알림 / 메시지 / 마케팅 알림 관리',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
            ],
          ),
        ),
      ),
    );
  }
}
