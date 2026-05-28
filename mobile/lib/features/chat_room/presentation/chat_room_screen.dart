/// F-016 — 채팅방 (`/chat/:idolId`).
///
/// 본문은 character 슬라이스가 전부 위임받음 (chatRoomCharacterSlotProvider).
/// PR-1 이후: RoomCanvas가 풀스크린 방+캐릭터+하단 반투명 채팅 카드까지 자체 렌더.
/// 본 화면은 AppBar + 접근 가드(active/header)만 담당.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../application/chat_list_controller.dart';
import '../application/slot_providers.dart';
import 'widgets/chat_room_menu_sheet.dart';

class ChatRoomScreen extends ConsumerWidget {
  const ChatRoomScreen({super.key, required this.idolId});

  final String idolId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(isActiveSubscriptionProvider(idolId));
    final headerAsync = ref.watch(idolHeaderProvider(idolId));
    final me = ref.watch(supabaseProvider).auth.currentUser?.id;
    final isIdolSelf = me != null && me == idolId;

    return Scaffold(
      // 캐릭터 방이 풀스크린이라 AppBar는 transparent overlay로.
      extendBodyBehindAppBar: true,
      // Scaffold 자체 배경은 transparent — AppBackground/방 배경 비침.
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: headerAsync.when(
          loading: () => const Text(''),
          error: (_, __) => const Text(''),
          data: (h) {
            final tappable = !isIdolSelf && h != null;
            final inner = Row(
              children: [
                Avatar(
                  imageUrl: h?.thumbnailUrl,
                  fallbackText: h?.displayName ?? '?',
                  size: 36,
                  idolRing: true,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    h?.displayName ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            );
            if (!tappable) return inner;
            return InkWell(
              onTap: () => context.push('/discover/$idolId'),
              child: inner,
            );
          },
        ),
        actions: [
          if (!isIdolSelf)
            IconButton(
              tooltip: '메뉴',
              icon: const Icon(Icons.more_vert),
              onPressed: () => showChatRoomMenu(
                context: context,
                idolId: idolId,
              ),
            ),
        ],
      ),
      body: activeAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(isActiveSubscriptionProvider(idolId)),
        ),
        data: (active) {
          if (!active) return const _BlockedView();
          return headerAsync.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () => ref.invalidate(idolHeaderProvider(idolId)),
            ),
            data: (header) {
              if (header == null) return const _NotFoundView();
              if (header.suspended) return const _SuspendedView();
              // character 슬라이스에 풀스크린 위임 — RoomCanvas가
              // 방 + 캐릭터 + 하단 반투명 채팅 카드까지 자체 렌더.
              return ref.watch(chatRoomCharacterSlotProvider(idolId));
            },
          );
        },
      ),
    );
  }
}

// ── 상태별 안내 ────────────────────────────────────

class _BlockedView extends StatelessWidget {
  const _BlockedView();
  @override
  Widget build(BuildContext context) => _Centered(
        icon: Icons.lock_outline,
        title: '응원하지 않는 아이돌입니다.',
        hint: '아이돌 탐색에서 응원을 시작하세요.',
        actionLabel: '아이돌 탐색',
        onAction: () {
          try {
            context.go('/discover');
          } catch (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('아이돌 탐색은 준비 중입니다.')),
            );
            context.pop();
          }
        },
      );
}

class _SuspendedView extends StatelessWidget {
  const _SuspendedView();
  @override
  Widget build(BuildContext context) => _Centered(
        icon: Icons.pause_circle_outline,
        title: '일시 정지된 아이돌입니다.',
        hint: '운영자 확인 후 다시 활성화됩니다.',
        actionLabel: '뒤로 가기',
        onAction: () => context.pop(),
      );
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();
  @override
  Widget build(BuildContext context) => _Centered(
        icon: Icons.help_outline,
        title: '아이돌 정보를 찾을 수 없어요.',
        hint: '주소가 잘못되었거나 삭제된 아이돌입니다.',
        actionLabel: '뒤로 가기',
        onAction: () => context.pop(),
      );
}

class _Centered extends StatelessWidget {
  const _Centered({
    required this.icon,
    required this.title,
    required this.hint,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String hint;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
