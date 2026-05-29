/// [임시] F-043 캐릭터 액션 수동 트리거 메뉴.
///
/// 채팅방 ⋮ 메뉴에서 진입 → bottom sheet에서 6종 액션 선택 → 백엔드 POST.
/// 추후 AI 기반 자동 트리거 도입 시 (F-047) 본 메뉴 제거 예정.
///
/// 호출 흐름:
///   chat_room ⋮ → "캐릭터 액션" 탭 → showActionSheet → state.trigger(action)
library;

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../chat_room/domain/chat_room_models.dart';
import '../application/character_state_controller.dart';
import '../domain/character_action.dart';

/// 채팅방 ⋮ 메뉴 — "캐릭터 액션" (임시 디버그 트리거).
ChatRoomMenuAction characterActionMenuAction(Ref ref) {
  return ChatRoomMenuAction(
    icon: Icons.auto_fix_high_outlined,
    label: '캐릭터 액션',
    onTap: (context, idolId) async {
      final messenger = ScaffoldMessenger.of(context);
      final selected = await showModalBottomSheet<CharacterActionType>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => _ActionSheet(),
      );
      if (selected == null) return;
      try {
        await ref
            .read(characterStateControllerProvider(idolId).notifier)
            .trigger(selected);
        messenger.showSnackBar(
          SnackBar(
            content: Text('캐릭터 액션: ${_label(selected)}'),
            duration: const Duration(seconds: 1),
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('액션 변경 실패: $e')),
        );
      }
    },
  );
}

class _ActionSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '캐릭터 액션 (임시 디버그)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final action in CharacterActionType.values)
                  ActionChip(
                    avatar: Icon(_icon(action), size: 18),
                    label: Text(_label(action)),
                    onPressed: () => Navigator.of(context).pop(action),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '추후 AI 자동 트리거 (F-047) 도입 시 본 메뉴 제거 예정.',
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

String _label(CharacterActionType a) {
  switch (a) {
    case CharacterActionType.idle:
      return '기본';
    case CharacterActionType.happy:
      return '기쁨';
    case CharacterActionType.sad:
      return '슬픔';
    case CharacterActionType.sing:
      return '노래';
    case CharacterActionType.eat:
      return '식사';
    case CharacterActionType.sleep:
      return '수면';
  }
}

IconData _icon(CharacterActionType a) {
  switch (a) {
    case CharacterActionType.idle:
      return Icons.person_outline;
    case CharacterActionType.happy:
      return Icons.sentiment_very_satisfied;
    case CharacterActionType.sad:
      return Icons.sentiment_dissatisfied;
    case CharacterActionType.sing:
      return Icons.music_note;
    case CharacterActionType.eat:
      return Icons.restaurant;
    case CharacterActionType.sleep:
      return Icons.bedtime;
  }
}
