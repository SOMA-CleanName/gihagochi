/// 채팅 말풍선 — 네온 다크 디자인 시스템 (Phase 2).
///
/// 본인/상대 구분 + 타임스탬프. 미디어(사진/음성)는 별도 위젯.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/colors.dart';
import '../theme/radius.dart';
import '../theme/spacing.dart';
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
    final bg = isMine ? AppColors.bubbleMine : AppColors.bubbleOther;
    final fg = isMine ? AppColors.onBubbleMine : AppColors.onBubbleOther;
    final radius = isMine
        ? AppBorderRadius.bubbleMine
        : AppBorderRadius.bubbleOther;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xs,
            horizontal: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm + 2,
                  horizontal: AppSpacing.md,
                ),
                decoration: BoxDecoration(color: bg, borderRadius: radius),
                child: Text(
                  text,
                  style: AppTextStyles.messageBody.copyWith(color: fg),
                ),
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
