// chat_room 시간 포맷 단위 테스트.
// "방금 전" / "n분 전" / "n시간 전" / "n일 전" / "YYYY-MM-DD" 분기 검증.

import 'package:flutter_test/flutter_test.dart';

import 'package:gihagochi/features/chat_room/application/time_format.dart';

void main() {
  group('formatChatRoomTime', () {
    final now = DateTime(2026, 5, 25, 12, 0, 0);

    test('1분 미만 → "방금 전"', () {
      expect(formatChatRoomTime(now.subtract(const Duration(seconds: 30)), now: now), '방금 전');
      expect(formatChatRoomTime(now, now: now), '방금 전');
    });

    test('1시간 미만 → "n분 전"', () {
      expect(formatChatRoomTime(now.subtract(const Duration(minutes: 5)), now: now), '5분 전');
      expect(formatChatRoomTime(now.subtract(const Duration(minutes: 59)), now: now), '59분 전');
    });

    test('24시간 미만 → "n시간 전"', () {
      expect(formatChatRoomTime(now.subtract(const Duration(hours: 3)), now: now), '3시간 전');
      expect(formatChatRoomTime(now.subtract(const Duration(hours: 23)), now: now), '23시간 전');
    });

    test('30일 미만 → "n일 전"', () {
      expect(formatChatRoomTime(now.subtract(const Duration(days: 1)), now: now), '1일 전');
      expect(formatChatRoomTime(now.subtract(const Duration(days: 29)), now: now), '29일 전');
    });

    test('30일 이상 → 날짜', () {
      expect(formatChatRoomTime(DateTime(2026, 3, 1, 9, 0), now: now), '2026-03-01');
    });

    test('미래 시간 → "방금 전"으로 안전 처리', () {
      expect(formatChatRoomTime(now.add(const Duration(minutes: 10)), now: now), '방금 전');
    });
  });
}
