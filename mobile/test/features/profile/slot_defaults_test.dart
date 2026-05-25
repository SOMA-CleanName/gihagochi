// profile 슬롯 default 위젯들이 정상적으로 렌더링되는지 확인.
//
// 실제 화면(MainScreen / MyPage) 통합 테스트는 Supabase/auth 초기화가 필요해서
// 별도 통합 테스트로 분리. 본 테스트는 슬롯 기본 위젯의 위젯 트리 검증만.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gihagochi/features/profile/presentation/widgets/slot_defaults.dart';

void main() {
  group('profile slot defaults', () {
    testWidgets('EmptyChatListSlot — 빈 상태 메시지 + CTA 노출', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: EmptyChatListSlot())));
      expect(find.text('응원 중인 아이돌이 없어요'), findsOneWidget);
      expect(find.text('아이돌 추가하기'), findsOneWidget);
    });

    testWidgets('PlaceholderSubscriptionSlot — 준비 중 카드', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PlaceholderSubscriptionSlot())));
      expect(find.text('응원 중인 아이돌'), findsOneWidget);
      expect(find.text('응원 기능은 곧 추가됩니다.'), findsOneWidget);
    });

    testWidgets('PlaceholderNotificationSlot — 알림 placeholder', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PlaceholderNotificationSlot())));
      expect(find.text('알림 설정'), findsOneWidget);
      expect(find.text('알림 설정은 곧 추가됩니다.'), findsOneWidget);
    });
  });
}
