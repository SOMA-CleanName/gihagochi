// F-027 gift — GiftComingSoonScreen widget 스모크.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gihagochi/features/gift/presentation/gift_coming_soon_sheet.dart';

void main() {
  testWidgets('GiftComingSoonScreen — 안내 + 확인 버튼 표시', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GiftComingSoonScreen(),
      ),
    );

    expect(find.text('선물하기 — 곧 만나요'), findsOneWidget);
    expect(find.textContaining('준비 중'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '확인'), findsOneWidget);
    expect(find.byIcon(Icons.card_giftcard), findsOneWidget);
  });

  testWidgets('GiftComingSoonScreen — idolId 전달돼도 렌더 OK', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GiftComingSoonScreen(idolId: 'abc-123'),
      ),
    );
    expect(find.text('선물하기 — 곧 만나요'), findsOneWidget);
  });

  testWidgets('showGiftComingSoonSheet — modal 노출', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showGiftComingSoonSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('선물하기 — 곧 만나요'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '확인'), findsOneWidget);
  });
}
