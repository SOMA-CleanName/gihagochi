/// F-016 — 채팅방 (`/chat/:idolId`).
///
/// AppBar (thumbnail + 닉네임 + ⋮ 메뉴) + 캐릭터 슬롯(접기 가능) + 메시지 + 입력.
/// 활성 subscription 아니거나 idol 정보 없으면 진입 차단.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../application/chat_list_controller.dart';
import '../application/slot_providers.dart';
import 'widgets/chat_room_menu_sheet.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({super.key, required this.idolId});

  final String idolId;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  bool _characterCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final activeAsync = ref.watch(isActiveSubscriptionProvider(widget.idolId));
    final headerAsync = ref.watch(idolHeaderProvider(widget.idolId));
    // 본인 == idolId면 ⋮ 메뉴 / AppBar 탭 비활성.
    final me = ref.watch(supabaseProvider).auth.currentUser?.id;
    final isIdolSelf = me != null && me == widget.idolId;

    return Scaffold(
      appBar: AppBar(
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
              onTap: () => context.push('/discover/${widget.idolId}'),
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
                idolId: widget.idolId,
              ),
            ),
        ],
      ),
      body: activeAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () =>
              ref.invalidate(isActiveSubscriptionProvider(widget.idolId)),
        ),
        data: (active) {
          if (!active) return const _BlockedView();
          // headerAsync도 함께 await — race condition으로 _NotFoundView 깜빡임 방지.
          return headerAsync.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () =>
                  ref.invalidate(idolHeaderProvider(widget.idolId)),
            ),
            data: (header) {
              if (header == null) return const _NotFoundView();
              if (header.suspended) return const _SuspendedView();
              return _ChatBody(
                idolId: widget.idolId,
                characterCollapsed: _characterCollapsed,
                onToggleCharacter: () => setState(
                  () => _characterCollapsed = !_characterCollapsed,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatBody extends ConsumerWidget {
  const _ChatBody({
    required this.idolId,
    required this.characterCollapsed,
    required this.onToggleCharacter,
  });

  final String idolId;
  final bool characterCollapsed;
  final VoidCallback onToggleCharacter;

  static const double _collapsedHeight = 36;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 키보드 안 보일 때 캐릭터 ~38%, 열려있을 때 ~22%.
    final mq = MediaQuery.of(context);
    final keyboardOpen = mq.viewInsets.bottom > 0;
    final fullHeight = (keyboardOpen ? 0.22 : 0.38) * mq.size.height;
    final charHeight = characterCollapsed ? _collapsedHeight : fullHeight;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          height: charHeight,
          child: ClipRect(
            child: _CharacterPanel(
              idolId: idolId,
              collapsed: characterCollapsed,
              onToggle: onToggleCharacter,
            ),
          ),
        ),
        Expanded(child: ref.watch(chatMessageListSlotProvider(idolId))),
        ref.watch(chatMessageInputSlotProvider(idolId)),
      ],
    );
  }
}

/// 캐릭터 슬롯 + 접기/펴기 핸들.
class _CharacterPanel extends ConsumerWidget {
  const _CharacterPanel({
    required this.idolId,
    required this.collapsed,
    required this.onToggle,
  });

  final String idolId;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (collapsed) {
      // 접힌 상태: 가는 capsule + 펴기 chevron.
      return Container(
        color: AppColors.surface.withValues(alpha: 0.6),
        alignment: Alignment.center,
        child: _HandleButton(
          icon: Icons.expand_more,
          tooltip: '캐릭터 펴기',
          onTap: onToggle,
        ),
      );
    }
    // 펼쳐진 상태: 캐릭터 슬롯 + 우상단 접기 핸들.
    return Stack(
      children: [
        Positioned.fill(child: ref.watch(chatRoomCharacterSlotProvider(idolId))),
        Positioned(
          top: AppSpacing.sm,
          right: AppSpacing.sm,
          child: _HandleButton(
            icon: Icons.expand_less,
            tooltip: '캐릭터 접기',
            onTap: onToggle,
          ),
        ),
      ],
    );
  }
}

class _HandleButton extends StatelessWidget {
  const _HandleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.85),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
          ),
        ),
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
