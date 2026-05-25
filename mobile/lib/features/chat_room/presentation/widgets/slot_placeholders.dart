/// chat_room 슬롯 default 위젯들.
///
/// chat_message 가 머지되기 전까지 채팅방 본문 자리를 메우는 placeholder.
library;

import 'package:flutter/material.dart';

/// `chatMessageListSlotProvider` default — 메시지 영역 placeholder.
class PlaceholderMessageList extends StatelessWidget {
  const PlaceholderMessageList({super.key, required this.idolId});
  final String idolId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              '메시지 기능은 곧 추가됩니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `chatMessageInputSlotProvider` default — 입력창 placeholder.
class PlaceholderMessageInput extends StatelessWidget {
  const PlaceholderMessageInput({super.key, required this.idolId});
  final String idolId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '입력 준비 중',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
