/// F-042/F-043 — 아이돌별 캐릭터 상태 관리.
///
/// build: GET /character/{idol_id}/state (default 응답 보장 — null 없음).
/// trigger(action): POST /character/{idol_id}/actions → state 즉시 갱신.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/character_repository.dart';
import '../domain/character_action.dart';
import '../domain/character_state.dart';

part 'character_state_controller.g.dart';

@riverpod
class CharacterStateController extends _$CharacterStateController {
  @override
  Future<CharacterState> build(String idolId) async {
    final repo = ref.watch(characterRepositoryProvider);
    return repo.fetchState(idolId);
  }

  Future<void> trigger(CharacterActionType action) async {
    final repo = ref.read(characterRepositoryProvider);
    final next = await repo.triggerAction(idolId, action);
    state = AsyncData(next);
  }

  /// PR-G2 — 드래그 위치 저장 (드래그 종료 시). 실패해도 로컬 위치는 유지.
  Future<void> savePosition(double x, double y) async {
    final repo = ref.read(characterRepositoryProvider);
    final next = await repo.savePosition(idolId, x, y);
    state = AsyncData(next);
  }
}
