/// F-015 — 채팅방 메뉴 BottomSheet.
///
/// 액션 리스트는 `chatRoomMenuActionsProvider` 가 정의. 다른 피처(report/subscription
/// /notification)가 머지 시 override 로 자기 액션 추가. 본 PR default = `[]`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/slot_providers.dart';

Future<void> showChatRoomMenu({
  required BuildContext context,
  required String idolId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => _ChatRoomMenu(idolId: idolId),
  );
}

class _ChatRoomMenu extends ConsumerWidget {
  const _ChatRoomMenu({required this.idolId});
  final String idolId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(chatRoomMenuActionsProvider);

    if (actions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.more_horiz,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              '메뉴 액션은 곧 추가됩니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final a in actions)
            ListTile(
              leading: Icon(
                a.icon,
                color: a.destructive
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
              title: Text(
                a.label,
                style: a.destructive
                    ? TextStyle(color: Theme.of(context).colorScheme.error)
                    : null,
              ),
              onTap: () {
                Navigator.of(context).pop();
                a.onTap(context, idolId);
              },
            ),
        ],
      ),
    );
  }
}
