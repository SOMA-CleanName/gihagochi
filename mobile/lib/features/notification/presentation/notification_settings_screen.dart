/// F-031 알림 설정 화면.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../application/notification_prefs_controller.dart';
import '../domain/notification_models.dart';
import 'widgets/pref_toggle_tile.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationPrefsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('알림 설정')),
      body: state.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref
              .read(notificationPrefsControllerProvider.notifier)
              .refresh(),
        ),
        data: (prefs) => ListView(
          children: [
            PrefToggleTile(
              title: '새 메시지 알림',
              subtitle: '응원 중인 아이돌의 새 메시지를 푸시로 받습니다.',
              value: prefs.newMessageEnabled,
              buildPatch: (v) => NotificationPrefsPatch(newMessageEnabled: v),
            ),
            const Divider(height: 0),
            PrefToggleTile(
              title: '아이돌 답글 알림',
              subtitle: '아이돌이 내 메시지에 답글을 달면 알려드립니다.',
              value: prefs.idolReplyEnabled,
              buildPatch: (v) => NotificationPrefsPatch(idolReplyEnabled: v),
            ),
            const Divider(height: 0),
            PrefToggleTile(
              title: '마케팅 알림',
              subtitle: '이벤트, 공지 등 마케팅성 알림을 받습니다.',
              value: prefs.marketingEnabled,
              buildPatch: (v) => NotificationPrefsPatch(marketingEnabled: v),
            ),
          ],
        ),
      ),
    );
  }
}
