/// F-017 — 메시지 입력창. chat_room 의 `chatMessageInputSlotProvider` override 대상.
///
/// 정책: 사진/음성은 **아이돌만** 송신 가능 (1:N 컨텐츠 발행).
/// 팬은 텍스트만 송신 — 입력창에 사진/마이크 버튼 자체가 안 보임.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/error/app_error.dart';
import '../../chat_media/presentation/photo_picker_sheet.dart';
import '../../chat_media/presentation/voice_recorder_button.dart';
import '../../gift/presentation/gift_coming_soon_sheet.dart';
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
    // 본인 = 채팅방 idolId 이면 아이돌 — 사진/음성 노출.
    // 그 외(팬)는 텍스트만.
    final me = ref.watch(supabaseProvider).auth.currentUser?.id;
    final isIdolSelf = me != null && me == widget.idolId;
    final hasText = _ctrl.text.trim().isNotEmpty;

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
            // F-027 선물 — 팬만. 정책 2026-05-27: ⋮ 메뉴에서 입력창 좌측으로 이동.
            if (!isIdolSelf)
              IconButton(
                tooltip: '선물',
                icon: const Icon(Icons.card_giftcard_outlined),
                onPressed: () => showGiftComingSoonSheet(
                  context,
                  idolId: widget.idolId,
                ),
              ),
            // F-019 사진 — 아이돌만.
            if (isIdolSelf)
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
            // 아이돌 + 입력 비어있을 때만 F-020 음성 버튼.
            // 팬은 입력 비어있으면 전송 disabled 버튼만.
            if (isIdolSelf && !hasText && !_sending)
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
                onPressed: (!hasText || _sending) ? null : _send,
              ),
          ],
        ),
      ),
    );
  }
}
