/// 채팅 말풍선 — 본인/상대 구분 + 타임스탬프.
///
/// 미디어(사진/음성)는 별도 위젯 (`features/chat_media/`)에서 처리.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.text,
    required this.createdAt,
    required this.isMine,
  });

  final String text;
  final DateTime createdAt;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final align = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final color = isMine ? AppColors.bubbleMine : AppColors.bubbleOther;
    final radius = isMine
        ? const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          );

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(color: color, borderRadius: radius),
                child: Text(text, style: AppTextStyles.messageBody),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('HH:mm').format(createdAt.toLocal()),
                style: AppTextStyles.messageTimestamp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
