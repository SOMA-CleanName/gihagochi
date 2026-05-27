/// F-016 — 채팅방 (`/chat/:idolId`).
///
/// AppBar (thumbnail + 활동명 + ⋮ 메뉴) + 메시지 슬롯 + 입력 슬롯.
/// 활성 subscription 아니거나 idol 정보 없으면 진입 차단.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_service.dart';
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
    // 본인이 아이돌(=idolId)이면 ⋮ 메뉴 노출 X — 본인 채팅방 나가기는 의미 없음.
    final me = ref.watch(supabaseProvider).auth.currentUser?.id;
    final isIdolSelf = me != null && me == idolId;

    return Scaffold(
      appBar: AppBar(
        title: headerAsync.when(
          loading: () => const Text(''),
          error: (_, __) => const Text(''),
          data: (h) {
            // 아바타+닉네임 탭 → 아이돌 프로필 화면 (#7b).
            // 본인 채팅방이면 탭 비활성 (자기 프로필은 마이 탭).
            final tappable = !isIdolSelf && h != null;
            final inner = Row(
              children: [
                Avatar(
                  imageUrl: h?.thumbnailUrl,
                  fallbackText: h?.displayName ?? '?',
                  size: 36,
                  idolRing: true,
                ),
                const SizedBox(width: 12),
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
              onPressed: () =>
                  showChatRoomMenu(context: context, idolId: idolId),
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
          final header = headerAsync.value;
          if (header == null) return const _NotFoundView();
          if (header.suspended) return const _SuspendedView();

          // 키보드 안 보일 때 캐릭터는 화면의 ~38% (절반 미만).
          // 키보드 올라오면 더 작게 (~22%) — 입력 가시성 보호.
          final mq = MediaQuery.of(context);
          final keyboardOpen = mq.viewInsets.bottom > 0;
          final charHeight =
              (keyboardOpen ? 0.22 : 0.38) * mq.size.height;
          return Column(
            children: [
              SizedBox(
                height: charHeight,
                child: ref.watch(chatRoomCharacterSlotProvider(idolId)),
              ),
              Expanded(child: ref.watch(chatMessageListSlotProvider(idolId))),
              ref.watch(chatMessageInputSlotProvider(idolId)),
            ],
          );
        },
      ),
    );
  }
}

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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
