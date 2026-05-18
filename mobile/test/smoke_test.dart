// 베이스라인 스모크: 테스트 하네스가 동작하는지만 확인.
// 실제 앱 부트는 Firebase/Supabase init 필요 → 피처 PR에서 통합 테스트로 추가.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('smoke: test harness runs', () {
    expect(1 + 1, 2);
  });
}
