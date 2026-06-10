/// F-042/F-043 — character backend repository.
///
/// 백엔드 (PR-2b/G2):
///   GET  /character/{idol_id}/state
///   POST /character/{idol_id}/actions    body={"action": "..."}
///   POST /character/{idol_id}/position   body={"x": .., "y": ..}
library;

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/dio_client.dart';
import '../domain/character_action.dart';
import '../domain/character_state.dart';

part 'character_repository.g.dart';

@riverpod
CharacterRepository characterRepository(Ref ref) {
  return CharacterRepository(dio: ref.watch(dioProvider));
}

class CharacterRepository {
  CharacterRepository({required this.dio});

  final Dio dio;

  Future<CharacterState> fetchState(String idolId) async {
    final res = await dio.get('/character/$idolId/state');
    return CharacterState.fromJson(res.data as Map<String, dynamic>);
  }

  /// POST 응답의 state 부분만 반환 (log는 mobile에서 미사용).
  Future<CharacterState> triggerAction(
    String idolId,
    CharacterActionType action,
  ) async {
    final res = await dio.post(
      '/character/$idolId/actions',
      data: {'action': action.name},
    );
    final body = res.data as Map<String, dynamic>;
    return CharacterState.fromJson(body['state'] as Map<String, dynamic>);
  }

  /// PR-G2 — 드래그 위치 저장. 응답은 갱신된 CharacterState (위치 포함).
  Future<CharacterState> savePosition(String idolId, double x, double y) async {
    final res = await dio.post(
      '/character/$idolId/position',
      data: {'x': x, 'y': y},
    );
    return CharacterState.fromJson(res.data as Map<String, dynamic>);
  }
}
