/// F-027 — "선물하기 준비 중" BottomSheet + 내부 위젯.
///
/// chat_room 등 진입 측이 [showGiftComingSoonSheet]를 호출.
/// `/gift` 라우트는 같은 콘텐츠를 FullScreen으로 표시 ([GiftComingSoonScreen]).
library;

import 'package:flutter/material.dart';

/// 진입 측 공개 함수 — modal bottom sheet로 안내 표시.
Future<void> showGiftComingSoonSheet(
  BuildContext context, {
  String? idolId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: _GiftComingSoonBody(idolId: idolId, isSheet: true),
      ),
    ),
  );
}

/// `/gift` 직접 진입용 FullScreen.
class GiftComingSoonScreen extends StatelessWidget {
  const GiftComingSoonScreen({super.key, this.idolId});

  final String? idolId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('선물하기')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _GiftComingSoonBody(idolId: idolId, isSheet: false),
      ),
    );
  }
}

class _GiftComingSoonBody extends StatelessWidget {
  const _GiftComingSoonBody({required this.idolId, required this.isSheet});

  final String? idolId;
  final bool isSheet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Icon(
          Icons.card_giftcard,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          '선물하기 — 곧 만나요',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          '아이돌에게 선물을 보낼 수 있는 기능을 준비 중입니다.\n조금만 기다려 주세요!',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('확인'),
        ),
        if (!isSheet) const SizedBox(height: 12),
      ],
    );
  }
}
