/// F-044 — 캐릭터 모먼트 상태 관리.
///
/// idolId별 현재 활성 moment 1개 (queue 안 함).
/// 동일 idolId 재트리거 = 기존 타이머 cancel + 새 moment 시작.
/// 5s 후 자동 dismiss.
library;

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/character_moment.dart';

part 'character_moment_controller.g.dart';

@riverpod
class CharacterMomentController extends _$CharacterMomentController {
  static const Duration showDuration = Duration(seconds: 5);

  Timer? _timer;

  @override
  CharacterMoment? build(String idolId) {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  void show(CharacterMomentKind kind, {String? message}) {
    _timer?.cancel();
    state = CharacterMoment(
      kind: kind,
      startedAt: DateTime.now(),
      message: message,
    );
    _timer = Timer(showDuration, () {
      if (state != null) state = null;
    });
  }

  void dismiss() {
    _timer?.cancel();
    state = null;
  }
}
