/// F-013 — chat_room의 `chatRoomMenuActionsProvider`에 끼울 "채팅방 나가기" 액션.
///
/// 본인 == idolId이면 노출 X (아이돌은 자기 채팅방 나갈 수 없음). 호출자가 가드.
/// main.dart의 chatRoomMenuActionsProvider override에서 합성.
library;

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../chat_room/domain/chat_room_models.dart';
import '../application/subscription_controller.dart';

/// 채팅방 ⋮ 메뉴 — "채팅방 나가기" (구독 취소). 확인 다이얼로그 → unsubscribe.
ChatRoomMenuAction unsubscribeMenuAction(Ref ref) {
  return ChatRoomMenuAction(
    icon: Icons.exit_to_app,
    label: '채팅방 나가기',
    destructive: true,
    onTap: (context, idolId) async {
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('채팅방 나가기'),
          content: const Text(
            '응원을 취소하면 채팅방에서 나가집니다.\n다시 응원하면 새로 시작합니다.',
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
      if (ok != true) return;
      try {
        await ref
            .read(subscriptionControllerProvider.notifier)
            .unsubscribe(idolId);
        if (navigator.canPop()) navigator.pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('채팅방을 나갔습니다.')),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('나가기 실패: $e')),
        );
      }
    },
  );
}
