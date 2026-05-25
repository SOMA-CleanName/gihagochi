/// F-007 — 팬 메인 화면 (`/main`).
///
/// 채팅방 리스트 영역은 슬롯 Provider로 비워둠 (chat_room이 머지 시 override).
/// 응원 0명이면 빈 상태. 아이돌은 본 화면 대신 `/my`로 redirect.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/domain/auth_models.dart' show UserRole;
import '../application/my_profile_controller.dart';
import '../application/slot_providers.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfile = ref.watch(myProfileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 채팅'),
        actions: [
          IconButton(
            tooltip: '마이페이지',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/my'),
          ),
        ],
      ),
      body: asyncProfile.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () =>
              ref.read(myProfileControllerProvider.notifier).refresh(),
        ),
        data: (profile) {
          // 아이돌은 F-024 머지 전까지 마이페이지로 임시 리다이렉트.
          if (profile.role == UserRole.idol) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/my');
            });
            return const LoadingView();
          }
          return ref.watch(chatListSlotProvider);
        },
      ),
    );
  }
}
