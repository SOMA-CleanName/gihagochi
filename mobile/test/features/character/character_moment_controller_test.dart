// F-044 character — moment controller 동작 검증.
//
// - show() → state 채워짐
// - dismiss() → state null
// - 재 show() → 이전 state 즉시 교체 (queue 안 함)
//
// 5s autoHide는 실시간 timer라 단위 테스트에서 생략.
// 위젯 통합 동작은 수동 시나리오에서 검증.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gihagochi/features/character/application/character_moment_controller.dart';
import 'package:gihagochi/features/character/domain/character_moment.dart';

void main() {
  group('CharacterMomentController', () {
    late ProviderContainer container;
    const idolId = 'idol-1';

    setUp(() {
      container = ProviderContainer();
      // autoDispose family — listen으로 활성화 유지.
      container.listen(
        characterMomentControllerProvider(idolId),
        (_, __) {},
      );
    });

    tearDown(() => container.dispose());

    test('초기 state == null', () {
      expect(
        container.read(characterMomentControllerProvider(idolId)),
        isNull,
      );
    });

    test('show(tap) → state 채워짐', () {
      container
          .read(characterMomentControllerProvider(idolId).notifier)
          .show(CharacterMomentKind.tap);

      final m = container.read(characterMomentControllerProvider(idolId));
      expect(m, isNotNull);
      expect(m!.kind, CharacterMomentKind.tap);
      expect(m.displayMessage, '반가워');
    });

    test('show(gift, message="땡큐") → 커스텀 메시지', () {
      container
          .read(characterMomentControllerProvider(idolId).notifier)
          .show(CharacterMomentKind.gift, message: '땡큐');

      final m = container.read(characterMomentControllerProvider(idolId));
      expect(m!.kind, CharacterMomentKind.gift);
      expect(m.displayMessage, '땡큐');
    });

    test('dismiss() → state == null', () {
      final notifier =
          container.read(characterMomentControllerProvider(idolId).notifier);
      notifier.show(CharacterMomentKind.praise);
      expect(
        container.read(characterMomentControllerProvider(idolId)),
        isNotNull,
      );

      notifier.dismiss();
      expect(
        container.read(characterMomentControllerProvider(idolId)),
        isNull,
      );
    });

    test('재 show() → 이전 moment 즉시 교체', () {
      final notifier =
          container.read(characterMomentControllerProvider(idolId).notifier);
      notifier.show(CharacterMomentKind.tap, message: '첫번째');
      expect(
        container
            .read(characterMomentControllerProvider(idolId))!
            .displayMessage,
        '첫번째',
      );

      notifier.show(CharacterMomentKind.gift, message: '두번째');
      final cur = container.read(characterMomentControllerProvider(idolId));
      expect(cur!.kind, CharacterMomentKind.gift);
      expect(cur.displayMessage, '두번째');
    });

    test('idolId family — 다른 idol은 독립', () {
      const idolA = 'idol-A';
      const idolB = 'idol-B';
      container.listen(characterMomentControllerProvider(idolA), (_, __) {});
      container.listen(characterMomentControllerProvider(idolB), (_, __) {});

      container
          .read(characterMomentControllerProvider(idolA).notifier)
          .show(CharacterMomentKind.tap);

      expect(
        container.read(characterMomentControllerProvider(idolA)),
        isNotNull,
      );
      expect(
        container.read(characterMomentControllerProvider(idolB)),
        isNull,
      );
    });
  });

  group('CharacterMoment.displayMessage 기본값', () {
    test('각 kind별 기본 문구', () {
      final now = DateTime.now();
      expect(
        CharacterMoment(kind: CharacterMomentKind.gift, startedAt: now)
            .displayMessage,
        '고마워!',
      );
      expect(
        CharacterMoment(kind: CharacterMomentKind.tap, startedAt: now)
            .displayMessage,
        '반가워',
      );
      expect(
        CharacterMoment(kind: CharacterMomentKind.feed, startedAt: now)
            .displayMessage,
        '잘 먹을게',
      );
      expect(
        CharacterMoment(kind: CharacterMomentKind.praise, startedAt: now)
            .displayMessage,
        '함께해서 행복해',
      );
    });
  });
}
