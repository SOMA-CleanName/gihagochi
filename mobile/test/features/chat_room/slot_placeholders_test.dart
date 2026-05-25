// chat_room 의 default 슬롯 placeholder 위젯 — 텍스트 렌더링 확인.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gihagochi/features/chat_room/presentation/widgets/slot_placeholders.dart';

void main() {
  testWidgets('PlaceholderMessageList — "메시지 기능은 곧 추가됩니다."', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: PlaceholderMessageList(idolId: 'x')),
    ));
    expect(find.text('메시지 기능은 곧 추가됩니다.'), findsOneWidget);
  });

  testWidgets('PlaceholderMessageInput — "입력 준비 중"', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: PlaceholderMessageInput(idolId: 'x')),
    ));
    expect(find.text('입력 준비 중'), findsOneWidget);
  });
}
