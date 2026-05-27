/// F-014 채팅방 카드 1장 — 리스트의 ListTile.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/avatar.dart';
import '../../application/time_format.dart';
import '../../domain/chat_room_models.dart';
import 'chat_room_menu_sheet.dart';

class ChatRoomCardTile extends StatelessWidget {
  const ChatRoomCardTile({super.key, required this.card});

  final ChatRoomCard card;

  @override
  Widget build(BuildContext context) {
    final preview = card.previewText ?? '아직 메시지가 없어요';
    final time = formatChatRoomTime(card.previewTime);
    final dim = card.idolSuspended;

    return ListTile(
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
      onLongPress: () => showChatRoomMenu(context: context, idolId: card.idolId),
    );
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
