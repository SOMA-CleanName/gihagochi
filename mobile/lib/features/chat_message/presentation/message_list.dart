/// F-018 / F-022 — 채팅방 메시지 리스트.
///
/// chat_room 의 `chatMessageListSlotProvider` 가 본 위젯으로 override 됨.
/// - 자동 스크롤 최하단 (초기 / 새 메시지가 도착했고 사용자가 하단 근처일 때)
/// - 위로 스크롤 시 추가 페이지 로딩
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_error.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/message_bubble.dart';
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

class _ConfirmedRow extends StatelessWidget {
  const _ConfirmedRow({required this.message, required this.isMine});
  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final body = switch (message.mediaType) {
      MediaType.text => message.content ?? '',
      MediaType.image => '[사진]',
      MediaType.audio => '[음성]',
    };
    if (message.deletedAt != null) {
      return MessageBubble(
        text: '(삭제된 메시지)',
        createdAt: message.createdAt,
        isMine: isMine,
      );
    }
    return MessageBubble(
      text: body,
      createdAt: message.createdAt,
      isMine: isMine,
    );
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

// AppError 가 import 만 되고 안 쓰임 — 호출자 위치 임포트 누락 방지용 hint.
// ignore: unused_element
typedef _AppErrorHint = AppError;
