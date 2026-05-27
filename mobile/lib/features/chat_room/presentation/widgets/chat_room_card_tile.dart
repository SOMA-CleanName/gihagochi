/// F-014 채팅방 카드 1장 — 리스트의 ListTile.
///
/// 우→좌 스와이프 = 채팅방 나가기 (subscription.unsubscribe).
/// 확인 다이얼로그 통과 후 실제 dismiss → chat_list invalidate.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/avatar.dart';
import '../../../subscription/application/subscription_controller.dart';
import '../../application/chat_list_controller.dart';
import '../../application/time_format.dart';
import '../../domain/chat_room_models.dart';
import 'chat_room_menu_sheet.dart';

class ChatRoomCardTile extends ConsumerWidget {
  const ChatRoomCardTile({super.key, required this.card});

  final ChatRoomCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = card.previewText ?? '아직 메시지가 없어요';
    final time = formatChatRoomTime(card.previewTime);
    final dim = card.idolSuspended;

    final tile = ListTile(
      leading: Opacity(
        opacity: dim ? 0.4 : 1.0,
        child: Avatar(
          imageUrl: card.thumbnailUrl,
          fallbackText: card.displayName,
          size: 56,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              card.displayName,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: dim ? Theme.of(context).disabledColor : null,
                  ),
            ),
          ),
          if (dim)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: _SuspendedBadge(),
            ),
        ],
      ),
      subtitle: Text(
        preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        time,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: () => context.push('/chat/${card.idolId}'),
      onLongPress: () =>
          showChatRoomMenu(context: context, idolId: card.idolId),
    );

    return Dismissible(
      key: ValueKey('chat-card-${card.idolId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.exit_to_app,
              color: Theme.of(context).colorScheme.onError,
            ),
            const SizedBox(width: 8),
            Text(
              '나가기',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onError,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) => _confirmLeave(context),
      onDismissed: (_) => _doUnsubscribe(context, ref),
      child: tile,
    );
  }

  Future<bool?> _confirmLeave(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('채팅방 나가기'),
        content: Text(
          '${card.displayName} 채팅방에서 나가시겠어요?\n다시 응원하면 새로 시작합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
  }

  Future<void> _doUnsubscribe(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(subscriptionControllerProvider.notifier)
          .unsubscribe(card.idolId);
      // 채팅 리스트 다시 fetch — 사라진 카드 반영.
      ref.invalidate(chatListControllerProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('채팅방을 나갔습니다.')),
      );
    } catch (e) {
      ref.invalidate(chatListControllerProvider);
      messenger.showSnackBar(
        SnackBar(content: Text('나가기 실패: $e')),
      );
    }
  }
}

class _SuspendedBadge extends StatelessWidget {
  const _SuspendedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '일시 정지',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
      ),
    );
  }
}
