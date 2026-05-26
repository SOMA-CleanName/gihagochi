// UUID v4 생성기 — 형식과 유일성 검증.

import 'package:flutter_test/flutter_test.dart';

import 'package:gihagochi/features/chat_message/application/uuid.dart';

void main() {
  group('generateUuidV4', () {
    test('format 8-4-4-4-12', () {
      final id = generateUuidV4();
      final re = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
      expect(re.hasMatch(id), isTrue, reason: 'malformed: $id');
    });

    test('uniqueness over 1000 calls', () {
      final ids = List.generate(1000, (_) => generateUuidV4());
      expect(ids.toSet().length, 1000);
    });
  });
}
