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
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/message_bubble.dart';
import '../../chat_media/presentation/photo_message_bubble.dart';
import '../../chat_media/presentation/voice_message_bubble.dart';
import '../../chat_meta/presentation/reply_badge.dart';
import '../../chat_meta/presentation/reply_composer_sheet.dart';
import '../application/chat_messages_controller.dart';
import '../application/sender_profile.dart';
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

        // 아이돌 본인 모드: fan_to_idol 메시지는 list에서 직접 노출 X,
        // 각 broadcast 다음에 그 사이 답장 카운트로 ReplyBadge 삽입.
        //
        // 팬(또는 admin) 모드: 채팅방은 본인 ↔ 아이돌 1:1.
        // RLS가 다른 팬 fan_to_idol을 가려야 하지만, admin/오너로 진입한 경우
        // RLS가 모두 노출하므로 클라이언트에서도 한 번 더 가드 — 본인이 보냈거나
        // 아이돌(idolId)이 보낸 메시지만.
        final me = ref.watch(supabaseProvider).auth.currentUser?.id;
        final isIdolSelf = me != null && me == widget.idolId;
        final baseRows = isIdolSelf
            ? _buildIdolRows(items, widget.idolId)
            : _buildFanRows(items, widget.idolId, me);
        // #5a — 날짜가 바뀌는 첫 메시지 위에 _DateSeparator 삽입 (카톡식).
        final rows = _injectDateSeparators(baseRows);

        return ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: rows.length,
          itemBuilder: (_, i) {
            final row = rows[i];
            return switch (row) {
              _MessageRow(item: final it) => _ItemRow(
                  item: it,
                  onRetry: (cid) => ref
                      .read(chatMessagesControllerProvider(widget.idolId)
                          .notifier)
                      .retry(cid),
                ),
              _BadgeRow(parentMessageId: final pid, count: final c) =>
                ReplyBadge(
                  idolId: widget.idolId,
                  parentMessageId: pid,
                  count: c,
                ),
              _DateSeparator(date: final d) => _DateSeparatorView(date: d),
            };
          },
        );
      },
    );
  }
}

// ── 아이돌 본인 모드 row 빌더 ────────────────

sealed class _Row {}

class _MessageRow extends _Row {
  _MessageRow(this.item);
  final ChatItem item;
}

class _BadgeRow extends _Row {
  _BadgeRow({required this.parentMessageId, required this.count});
  final String parentMessageId;
  final int count;
}

class _DateSeparator extends _Row {
  _DateSeparator(this.date);
  final DateTime date;
}

/// 메시지 사이에 날짜가 바뀌는 시점마다 _DateSeparator 한 줄 삽입.
/// 입력은 ASC 정렬 가정 (chat_messages_controller가 그렇게 빌드).
List<_Row> _injectDateSeparators(List<_Row> rows) {
  final out = <_Row>[];
  DateTime? lastDate;
  for (final r in rows) {
    DateTime? rowDate;
    if (r is _MessageRow) {
      rowDate = r.item.createdAt.toLocal();
    }
    if (rowDate != null) {
      final day = DateTime(rowDate.year, rowDate.month, rowDate.day);
      if (lastDate == null || day != lastDate) {
        out.add(_DateSeparator(day));
        lastDate = day;
      }
    }
    out.add(r);
  }
  return out;
}

class _DateSeparatorView extends StatelessWidget {
  const _DateSeparatorView({required this.date});
  final DateTime date;

  String _label(DateTime d) {
    final today = DateTime.now();
    final today0 = DateTime(today.year, today.month, today.day);
    final diffDays = today0.difference(d).inDays;
    if (diffDays == 0) return '오늘';
    if (diffDays == 1) return '어제';
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final wd = weekdays[d.weekday - 1];
    return '${d.year}년 ${d.month}월 ${d.day}일 ($wd)';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: scheme.outlineVariant, height: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              _label(date),
              style: TextStyle(fontSize: 11, color: scheme.outline),
            ),
          ),
          Expanded(
            child: Divider(color: scheme.outlineVariant, height: 1),
          ),
        ],
      ),
    );
  }
}

/// 아이돌 본인 채팅방 그룹화:
/// - 본인의 idol_to_fans / idol_reply (broadcast) 행은 그대로 노출
/// - 그 사이의 fan_to_idol 메시지는 카운트만 → ReplyBadge 한 줄로 흡수
/// - pending (본인 텍스트 송신 중) 행은 그대로 노출
List<_Row> _buildIdolRows(List<ChatItem> items, String idolId) {
  final out = <_Row>[];
  String? currentParentId;
  int pendingCount = 0;

  void flushBadge() {
    if (currentParentId != null && pendingCount > 0) {
      out.add(_BadgeRow(
        parentMessageId: currentParentId!,
        count: pendingCount,
      ));
    }
    currentParentId = null;
    pendingCount = 0;
  }

  for (final item in items) {
    if (item is ConfirmedItem) {
      final m = item.message;
      final isBroadcastByMe = (m.type == MessageType.idolToFans ||
              m.type == MessageType.idolReply) &&
          m.senderId == idolId;
      final isFanToIdol = m.type == MessageType.fanToIdol;

      if (isBroadcastByMe) {
        flushBadge();
        out.add(_MessageRow(item));
        currentParentId = m.id;
        pendingCount = 0;
        continue;
      }
      if (isFanToIdol) {
        if (currentParentId != null) {
          pendingCount += 1;
        }
        // currentParentId == null (첫 broadcast 전 답장)이면 무시 — 본인이 보낸 게
        // 없는 채팅방에 도착한 답장은 일반적이지 않음.
        continue;
      }
      // 그 외(드물게 RLS 우회) — 안전하게 그대로 노출.
      out.add(_MessageRow(item));
    } else {
      // pending — 본인 텍스트 송신 중. 그대로 노출.
      out.add(_MessageRow(item));
    }
  }
  flushBadge();
  return out;
}

/// 팬(또는 admin) 모드 row 빌더 — 본인 ↔ 아이돌 1:1 뷰.
/// - 본인이 보낸 메시지(sender == me)는 노출
/// - 아이돌이 보낸 broadcast(sender == idolId, type idol_to_fans/idol_reply)는 노출
/// - 그 외(다른 팬의 fan_to_idol 등)는 숨김
/// - pending(본인 송신 중)은 항상 노출
List<_Row> _buildFanRows(List<ChatItem> items, String idolId, String? me) {
  final out = <_Row>[];
  for (final item in items) {
    if (item is ConfirmedItem) {
      final m = item.message;
      final isMine = me != null && m.senderId == me;
      final isIdolBroadcast = m.senderId == idolId &&
          (m.type == MessageType.idolToFans ||
              m.type == MessageType.idolReply);
      if (isMine || isIdolBroadcast) {
        out.add(_MessageRow(item));
      }
      // 그 외 (다른 팬 fan_to_idol 등) — 숨김.
    } else {
      // pending — 항상 본인 송신 중.
      out.add(_MessageRow(item));
    }
  }
  return out;
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
    if (message.deletedAt != null) {
      return MessageBubble(
        text: '(삭제된 메시지)',
        createdAt: message.createdAt,
        isMine: isMine,
      );
    }

    // F-019/F-020: media_type 별로 chat_media 위젯 사용. media_url 없으면 placeholder.
    final innerBubble = switch (message.mediaType) {
      MediaType.text => MessageBubble(
          text: message.content ?? '',
          createdAt: message.createdAt,
          isMine: isMine,
        ),
      MediaType.photo => message.mediaUrl != null
          ? PhotoMessageBubble(
              storagePath: message.mediaUrl!,
              isMine: isMine,
              createdAt: message.createdAt,
            )
          : MessageBubble(
              text: '[사진]',
              createdAt: message.createdAt,
              isMine: isMine,
            ),
      MediaType.voice => message.mediaUrl != null
          ? VoiceMessageBubble(
              storagePath: message.mediaUrl!,
              isMine: isMine,
              createdAt: message.createdAt,
            )
          : MessageBubble(
              text: '[음성]',
              createdAt: message.createdAt,
              isMine: isMine,
            ),
    };

    // F-026: 수정된 메시지는 시각 옆에 작은 (수정됨) 라벨.
    final bubbleWithEdited = Column(
      crossAxisAlignment:
          isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        innerBubble,
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

    // 상대 메시지 — 좌측 sender 아바타 + 닉네임(#7a).
    final senderAsync = ref.watch(
      senderProfileProvider(senderId: message.senderId, idolId: message.idolId),
    );
    final senderName = senderAsync.maybeWhen(
      data: (s) => s.displayName,
      orElse: () => '',
    );
    final withSender = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Avatar(
              imageUrl: null,
              fallbackText: senderName.isNotEmpty ? senderName : '?',
              size: 32,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (senderName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 14, bottom: 2, top: 2),
                    child: Text(
                      senderName,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ),
                bubbleWithEdited,
              ],
            ),
          ),
        ],
      ),
    );

    // 아이돌이 받은 fan_to_idol → F-023 reply composer.
    final me = ref.watch(supabaseProvider).auth.currentUser?.id;
    final canReply = me != null &&
        me == message.idolId &&
        message.type == MessageType.fanToIdol;
    if (!canReply) return withSender;
    return GestureDetector(
      onLongPress: () => showReplyComposerSheet(
        context,
        parentMessageId: message.id,
        parentPreviewContent: message.content,
      ),
      child: withSender,
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
