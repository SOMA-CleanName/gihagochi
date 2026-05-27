/// F-017 — 메시지 입력창. chat_room 의 `chatMessageInputSlotProvider` override 대상.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_error.dart';
import '../../chat_media/presentation/photo_picker_sheet.dart';
import '../../chat_media/presentation/voice_recorder_button.dart';
import '../application/chat_messages_controller.dart';

class MessageInput extends ConsumerStatefulWidget {
  const MessageInput({super.key, required this.idolId});
  final String idolId;

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // 입력 비어있을 때 음성 버튼, 있을 때 전송 버튼 — 토글용 rebuild.
    _ctrl.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onChanged);
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _ctrl.clear();
    try {
      await ref
          .read(chatMessagesControllerProvider(widget.idolId).notifier)
          .sendText(text);
    } catch (e) {
      if (!mounted) return;
      final msg = e is AppError ? e.userMessage : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('전송 실패: $msg')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // F-019 사진
            IconButton(
              tooltip: '사진',
              icon: const Icon(Icons.photo_camera_outlined),
              onPressed: () => showPhotoPickerSheet(
                context,
                idolId: widget.idolId,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _ctrl,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(
                  hintText: '메시지 입력',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 4),
            // 입력 비어있으면 F-020 음성 버튼, 있으면 전송 버튼.
            if (_ctrl.text.trim().isEmpty && !_sending)
              VoiceRecorderButton(idolId: widget.idolId)
            else
              IconButton(
                tooltip: '전송',
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                onPressed: _sending ? null : _send,
              ),
          ],
        ),
      ),
    );
  }
}
