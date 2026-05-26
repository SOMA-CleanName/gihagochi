/// F-023 — 아이돌 답글 BottomSheet.
///
/// chat_message가 fan_to_idol 메시지 롱프레스 시 [showReplyComposerSheet] 호출.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat_message/application/uuid.dart';
import '../data/chat_meta_repository.dart';

/// 진입 측 공개 함수. parent fan_to_idol 메시지 ID + (선택)미리보기 받음.
Future<void> showReplyComposerSheet(
  BuildContext context, {
  required String parentMessageId,
  String? parentPreviewContent,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: SafeArea(
        child: _ReplyComposerBody(
          parentMessageId: parentMessageId,
          parentPreviewContent: parentPreviewContent,
        ),
      ),
    ),
  );
}

class _ReplyComposerBody extends ConsumerStatefulWidget {
  const _ReplyComposerBody({
    required this.parentMessageId,
    required this.parentPreviewContent,
  });

  final String parentMessageId;
  final String? parentPreviewContent;

  @override
  ConsumerState<_ReplyComposerBody> createState() => _ReplyComposerBodyState();
}

class _ReplyComposerBodyState extends ConsumerState<_ReplyComposerBody> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(chatMetaRepositoryProvider).sendIdolReply(
            parentMessageId: widget.parentMessageId,
            content: content,
            clientMessageId: generateUuidV4(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('답글을 보냈습니다. 모든 팬에게 공개됩니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('답글 전송 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.reply),
              const SizedBox(width: 8),
              Text('답글 (모든 팬에게 공개)', style: theme.textTheme.titleMedium),
            ],
          ),
          if ((widget.parentPreviewContent ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.parentPreviewContent!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF616161),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 6,
            maxLength: 1000,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: '답글 내용을 입력하세요',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: (_controller.text.trim().isEmpty || _busy) ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('답글 보내기'),
          ),
        ],
      ),
    );
  }
}
