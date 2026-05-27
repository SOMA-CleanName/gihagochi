/// F-018 / F-022 — 채팅방 메시지 리스트.
///
/// chat_room 의 `chatMessageListSlotProvider` 가 본 위젯으로 override 됨.
/// - 자동 스크롤 최하단 (초기 / 새 메시지가 도착했고 사용자가 하단 근처일 때)
/// - 위로 스크롤 시 추가 페이지 로딩
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_error.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/message_bubble.dart';
import '../../chat_meta/presentation/reply_composer_sheet.dart';
import '../application/chat_messages_controller.dart';
import '../domain/chat_item.dart';
import '../domain/message.dart';

class MessageList extends ConsumerStatefulWidget {
  const MessageList({super.key, required this.idolId});
  final String idolId;

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> {
  final _scroll = ScrollController();
  int _lastLen = 0;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels < 80 && !_loadingMore) {
      _loadingMore = true;
      ref
          .read(chatMessagesControllerProvider(widget.idolId).notifier)
          .loadMore()
          .whenComplete(() => _loadingMore = false);
    }
  }

  bool _nearBottom() {
    if (!_scroll.hasClients) return true;
    final max = _scroll.position.maxScrollExtent;
    return (max - _scroll.position.pixels) < 200;
  }

  void _autoScrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      if (jump) {
        _scroll.jumpTo(max);
      } else {
        _scroll.animateTo(
          max,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncItems = ref.watch(chatMessagesControllerProvider(widget.idolId));

    return asyncItems.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        error: e,
        onRetry: () => ref.invalidate(
          chatMessagesControllerProvider(widget.idolId),
        ),
      ),
      data: (items) {
        // 새 메시지 도착 자동 스크롤 — 초기 진입 시 jump, 그 외엔 near-bottom 일 때만.
        final added = items.length > _lastLen;
        if (added && _lastLen == 0) {
          _autoScrollToBottom(jump: true);
        } else if (added && _nearBottom()) {
          _autoScrollToBottom();
        }
        _lastLen = items.length;

        if (items.isEmpty) return const _EmptyMessages();

        return ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length,
          itemBuilder: (_, i) => _ItemRow(
            item: items[i],
            onRetry: (cid) => ref
                .read(chatMessagesControllerProvider(widget.idolId).notifier)
                .retry(cid),
          ),
        );
      },
    );
  }
}

class _EmptyMessages extends StatelessWidget {
  const _EmptyMessages();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '첫 메시지를 보내보세요',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.onRetry});

  final ChatItem item;
  final Future<void> Function(String clientMessageId) onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (item) {
      ConfirmedItem(message: final m, isMine: final mine) =>
        _ConfirmedRow(message: m, isMine: mine),
      PendingItem(
        clientMessageId: final cid,
        content: final c,
        createdAt: final ts,
        failed: final f,
      ) =>
        _PendingRow(
          content: c,
          createdAt: ts,
          failed: f,
          onRetry: () => onRetry(cid),
        ),
    };
  }
}

class _ConfirmedRow extends ConsumerWidget {
  const _ConfirmedRow({required this.message, required this.isMine});
  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = switch (message.mediaType) {
      MediaType.text => message.content ?? '',
      MediaType.photo => '[사진]',
      MediaType.voice => '[음성]',
    };
    if (message.deletedAt != null) {
      return MessageBubble(
        text: '(삭제된 메시지)',
        createdAt: message.createdAt,
        isMine: isMine,
      );
    }
    // F-026: 수정된 메시지는 시각 옆에 작은 (수정됨) 라벨.
    final bubbleWithEdited = Column(
      crossAxisAlignment:
          isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        MessageBubble(
          text: body,
          createdAt: message.createdAt,
          isMine: isMine,
        ),
        if (message.editedAt != null)
          Padding(
            padding: EdgeInsets.only(
              top: 0,
              left: isMine ? 0 : 16,
              right: isMine ? 16 : 0,
              bottom: 4,
            ),
            child: Text(
              '수정됨',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
      ],
    );

    // 본인 메시지 → F-026 수정/삭제 BottomSheet.
    if (isMine) {
      return GestureDetector(
        onLongPress: () => _showOwnerMenu(context, ref),
        child: bubbleWithEdited,
      );
    }

    // 아이돌이 받은 fan_to_idol → F-023 reply composer.
    final me = ref.watch(supabaseProvider).auth.currentUser?.id;
    final canReply = me != null &&
        me == message.idolId &&
        message.type == MessageType.fanToIdol;
    if (!canReply) return bubbleWithEdited;
    return GestureDetector(
      onLongPress: () => showReplyComposerSheet(
        context,
        parentMessageId: message.id,
        parentPreviewContent: message.content,
      ),
      child: bubbleWithEdited,
    );
  }

  // ── F-026 — 본인 메시지 수정 / 삭제 ──────────────

  Future<void> _showOwnerMenu(BuildContext context, WidgetRef ref) async {
    final canEdit = message.mediaType == MediaType.text;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canEdit)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('메시지 수정'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showEditDialog(context, ref);
                },
              ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                '메시지 삭제',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _confirmDelete(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    // TextEditingController 의 lifecycle 을 StatefulWidget 에 맞춰서
    // dispose race 회피 (`_dependents.isEmpty` 어설션 방어).
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _EditDialog(initial: message.content ?? ''),
    );
    if (result == null || result.isEmpty || result == message.content) return;
    try {
      await ref
          .read(chatMessagesControllerProvider(message.idolId).notifier)
          .editMessage(messageId: message.id, newContent: result);
    } catch (e) {
      if (!context.mounted) return;
      final msg = e is AppError ? e.userMessage : e.toString();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('수정 실패: $msg')));
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('메시지 삭제'),
        content: const Text(
          '정말 삭제하시겠습니까?\n삭제된 메시지는 모든 사용자 화면에서 "(삭제된 메시지)"로 표시됩니다.',
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
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(chatMessagesControllerProvider(message.idolId).notifier)
          .deleteMessage(messageId: message.id);
    } catch (e) {
      if (!context.mounted) return;
      final msg = e is AppError ? e.userMessage : e.toString();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('삭제 실패: $msg')));
    }
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({
    required this.content,
    required this.createdAt,
    required this.failed,
    required this.onRetry,
  });

  final String content;
  final DateTime createdAt;
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        MessageBubble(text: content, createdAt: createdAt, isMine: true),
        Positioned(
          right: 4,
          bottom: 4,
          child: failed
              ? GestureDetector(
                  onTap: onRetry,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 16,
                    ),
                  ),
                )
              : const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
        ),
      ],
    );
  }
}

/// F-026 수정 다이얼로그 — TextEditingController 를 state 로 관리해서
/// showDialog pop 직후 dispose race ('_dependents.isEmpty' assertion) 회피.
class _EditDialog extends StatefulWidget {
  const _EditDialog({required this.initial});
  final String initial;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('메시지 수정'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        maxLines: null,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text.trim()),
          child: const Text('저장'),
        ),
      ],
    );
  }
}

// AppError 가 import 만 되고 안 쓰임 — 호출자 위치 임포트 누락 방지용 hint.
// ignore: unused_element
typedef _AppErrorHint = AppError;
