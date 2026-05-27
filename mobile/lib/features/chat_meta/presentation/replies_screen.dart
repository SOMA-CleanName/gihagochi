/// 아이돌이 본인 broadcast에 도착한 fan_to_idol 답장들을 모아 보는 화면.
///
/// 라우트: `/chat/:idolId/replies/:messageId`.
/// 1. parent broadcast(messageId)의 created_at 조회
/// 2. 다음 broadcast(idol_to_fans/idol_reply by 본인) 의 created_at 조회 (없으면 null)
/// 3. 그 range의 fan_to_idol 메시지 + sender display_name fetch
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../data/chat_meta_repository.dart';
import '../domain/fan_reply.dart';

class RepliesScreen extends ConsumerWidget {
  const RepliesScreen({
    super.key,
    required this.idolId,
    required this.parentMessageId,
  });

  final String idolId;
  final String parentMessageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(
      _repliesContextProvider((idolId: idolId, messageId: parentMessageId)),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('답장 보기')),
      body: asyncData.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e),
        data: (ctx) {
          if (ctx.replies.isEmpty) {
            return const Center(child: Text('아직 답장이 없습니다.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: ctx.replies.length + 1,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (_, i) {
              if (i == 0) {
                return _ParentPreview(content: ctx.parentContent);
              }
              return _ReplyRow(reply: ctx.replies[i - 1]);
            },
          );
        },
      ),
    );
  }
}

class _ParentPreview extends StatelessWidget {
  const _ParentPreview({required this.content});
  final String? content;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '내가 보낸 메시지',
            style: TextStyle(
              fontSize: 11,
              color: scheme.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            (content == null || content!.trim().isEmpty)
                ? '(텍스트 없음)'
                : content!,
            style: const TextStyle(fontSize: 14),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ReplyRow extends StatelessWidget {
  const _ReplyRow({required this.reply});
  final FanReply reply;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final time = DateFormat('MM-dd HH:mm').format(reply.createdAt.toLocal());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              reply.sender.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(width: 8),
            Text(time, style: TextStyle(fontSize: 11, color: scheme.outline)),
          ],
        ),
        const SizedBox(height: 4),
        Text(reply.content ?? '', style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

// ── 데이터 fetch ─────────────────────────────

typedef _Args = ({String idolId, String messageId});

class _RepliesContext {
  const _RepliesContext({required this.parentContent, required this.replies});
  final String? parentContent;
  final List<FanReply> replies;
}

final _repliesContextProvider = FutureProvider.autoDispose
    .family<_RepliesContext, _Args>((ref, args) async {
  final supabase = ref.watch(supabaseProvider);
  // 1. parent broadcast 조회 (created_at + content).
  final parentRow = await supabase
      .from('messages')
      .select('id, content, created_at, idol_id, sender_id, type')
      .eq('id', args.messageId)
      .maybeSingle();
  if (parentRow == null) {
    throw StateError('해당 메시지를 찾을 수 없습니다.');
  }
  final parentCreatedAt = DateTime.parse(parentRow['created_at'] as String);
  final parentContent = parentRow['content'] as String?;

  // 2. 다음 broadcast(본인의 idol_to_fans/idol_reply) 조회.
  final nextRow = await supabase
      .from('messages')
      .select('created_at')
      .eq('idol_id', args.idolId)
      .eq('sender_id', args.idolId)
      .inFilter('type', ['idol_to_fans', 'idol_reply'])
      .gt('created_at', parentCreatedAt.toUtc().toIso8601String())
      .order('created_at', ascending: true)
      .limit(1)
      .maybeSingle();
  final toCreatedAt = nextRow == null
      ? null
      : DateTime.parse(nextRow['created_at'] as String);

  // 3. 그 range의 fan_to_idol + sender 닉네임 fetch.
  final replies = await ref.read(chatMetaRepositoryProvider).fetchFanRepliesBetween(
        idolId: args.idolId,
        fromCreatedAt: parentCreatedAt,
        toCreatedAt: toCreatedAt,
      );
  return _RepliesContext(parentContent: parentContent, replies: replies);
});
