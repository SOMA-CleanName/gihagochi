/// F-016 — 채팅방 (`/chat/:idolId`).
///
/// AppBar (thumbnail + 닉네임 + ⋮ 메뉴) + 캐릭터 슬롯(드래그 접기) + 메시지 + 입력.
/// 캐릭터 영역 하단 capsule 핸들을 위/아래로 드래그하면 height 자유 조절.
/// 드래그 end 시 가까운 상태(접힘/펴짐)로 snap.
library;

import 'dart:ui' show lerpDouble;

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
  @override
  Widget build(BuildContext context) {
    final activeAsync = ref.watch(isActiveSubscriptionProvider(widget.idolId));
    final headerAsync = ref.watch(idolHeaderProvider(widget.idolId));
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
              return _ChatBody(idolId: widget.idolId);
            },
          );
        },
      ),
    );
  }
}

class _ChatBody extends ConsumerStatefulWidget {
  const _ChatBody({required this.idolId});
  final String idolId;

  @override
  ConsumerState<_ChatBody> createState() => _ChatBodyState();
}

class _ChatBodyState extends ConsumerState<_ChatBody>
    with SingleTickerProviderStateMixin {
  /// 0.0 = 접힘 (캐릭터 영역 = _collapsedHeight)
  /// 1.0 = 펼침 (캐릭터 영역 = fullHeight)
  late final AnimationController _heightCtrl;
  bool _isDragging = false;

  static const double _collapsedHeight = 32;

  @override
  void initState() {
    super.initState();
    _heightCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    super.dispose();
  }

  double _fullHeight(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboardOpen = mq.viewInsets.bottom > 0;
    return (keyboardOpen ? 0.22 : 0.38) * mq.size.height;
  }

  void _onDragStart(DragStartDetails _) {
    _heightCtrl.stop();
    setState(() => _isDragging = true);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final full = _fullHeight(context);
    final range = full - _collapsedHeight;
    if (range <= 0) return;
    // 위로 드래그 (dy < 0) → height 감소 (접힘) → value 감소
    // 아래로 드래그 (dy > 0) → height 증가 (펴짐) → value 증가
    _heightCtrl.value =
        (_heightCtrl.value + details.delta.dy / range).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() => _isDragging = false);
    final velocity = details.velocity.pixelsPerSecond.dy;
    // 빠른 swipe 우선, 그 외엔 가까운 쪽으로 snap.
    final target = velocity.abs() > 400
        ? (velocity > 0 ? 1.0 : 0.0)
        : (_heightCtrl.value > 0.5 ? 1.0 : 0.0);
    _heightCtrl.animateTo(target, curve: Curves.easeOutCubic);
  }

  void _toggleTap() {
    final target = _heightCtrl.value > 0.5 ? 0.0 : 1.0;
    _heightCtrl.animateTo(target, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _heightCtrl,
      builder: (context, _) {
        final full = _fullHeight(context);
        final h = lerpDouble(_collapsedHeight, full, _heightCtrl.value)!;
        return Column(
          children: [
            SizedBox(
              height: h,
              child: _CharacterPanel(
                idolId: widget.idolId,
                value: _heightCtrl.value,
                isDragging: _isDragging,
                onDragStart: _onDragStart,
                onDragUpdate: _onDragUpdate,
                onDragEnd: _onDragEnd,
                onHandleTap: _toggleTap,
              ),
            ),
            Expanded(
              child: ref.watch(chatMessageListSlotProvider(widget.idolId)),
            ),
            ref.watch(chatMessageInputSlotProvider(widget.idolId)),
          ],
        );
      },
    );
  }
}

class _CharacterPanel extends ConsumerWidget {
  const _CharacterPanel({
    required this.idolId,
    required this.value,
    required this.isDragging,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onHandleTap,
  });

  final String idolId;
  final double value; // 0..1
  final bool isDragging;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final VoidCallback onHandleTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 거의 접혔을 때(<0.08)는 캐릭터 슬롯 paint X — 핸들만 노출.
    final showCharacter = value > 0.08;
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        if (showCharacter)
          Positioned.fill(
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: ref.watch(chatRoomCharacterSlotProvider(idolId)),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _DragHandle(
            isDragging: isDragging,
            onDragStart: onDragStart,
            onDragUpdate: onDragUpdate,
            onDragEnd: onDragEnd,
            onTap: onHandleTap,
          ),
        ),
      ],
    );
  }
}

/// 캐릭터 영역 하단의 드래그 핸들 (iOS-style capsule pill).
class _DragHandle extends StatelessWidget {
  const _DragHandle({
    required this.isDragging,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTap,
  });

  final bool isDragging;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: onDragStart,
      onVerticalDragUpdate: onDragUpdate,
      onVerticalDragEnd: onDragEnd,
      onTap: onTap,
      child: Container(
        height: 24,
        // 위쪽 영역까지 hit 잡히도록 투명 배경.
        color: Colors.transparent,
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: isDragging ? 56 : 44,
          height: 5,
          decoration: BoxDecoration(
            color: isDragging
                ? AppColors.primary.withValues(alpha: 0.8)
                : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(3),
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
