// F-033 report — 신고 모달 widget 스모크.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gihagochi/features/report/presentation/report_sheet.dart';

void main() {
  testWidgets('showReportSheet — 모달 노출 + 입력 필드 + 신고 버튼', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showReportSheet(context, messageId: 'test-msg-id'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('메시지 신고'), findsOneWidget);
    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '신고하기'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('신고 버튼은 reason 10자 미만일 때 비활성', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showReportSheet(context, messageId: 'm'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 5자 입력 (< 10) → 버튼 비활성
    await tester.enterText(find.byType(TextField), '12345');
    await tester.pump();
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    // 10자 입력 → 버튼 활성
    await tester.enterText(find.byType(TextField), '1234567890');
    await tester.pump();
    final button2 = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button2.onPressed, isNotNull);
  });
}
