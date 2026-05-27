/// 아이돌 본인 채팅방에서 broadcast 아래에 붙는 "답장 N개 보기" 말풍선.
///
/// 답장 1+개일 때만 노출. 클릭 시 답장 보기 화면으로 push.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReplyBadge extends StatelessWidget {
  const ReplyBadge({
    super.key,
    required this.idolId,
    required this.parentMessageId,
    required this.count,
  });

  final String idolId;
  final String parentMessageId;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 12, 6),
        child: Material(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push(
              '/chat/$idolId/replies/$parentMessageId',
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.forum_outlined, size: 14, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    '답장 $count개 보기',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
