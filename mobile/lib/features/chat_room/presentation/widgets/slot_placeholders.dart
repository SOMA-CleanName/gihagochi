/// chat_room 슬롯 default 위젯들.
///
/// chat_message / character 슬라이스가 머지되기 전까지 자리 placeholder.
library;

import 'package:flutter/material.dart';

/// `chatRoomCharacterSlotProvider` default — 2.5D AI 캐릭터 placeholder.
///
/// 채팅방 상단 ~40% 영역. 실제 캐릭터 슬라이스 머지 시 ProviderScope override.
class PlaceholderCharacter extends StatelessWidget {
  const PlaceholderCharacter({super.key, required this.idolId});
  final String idolId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.surfaceContainerHighest,
            scheme.surface,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_pin,
              size: 56,
              color: scheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              'AI 캐릭터 준비 중',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

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
