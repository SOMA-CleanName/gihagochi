/// PR-G2 — 캐릭터 위치/상태 로컬 캐시 (SharedPreferences).
///
/// 백엔드 GET state가 느릴 때(cold start 등) 진입 즉시 복원하기 위한 캐시.
/// 드래그 저장 시 낙관적으로 갱신 → 다음 진입 때 서버 응답을 기다리지 않고 바로 적용.
/// 서버 fetch는 백그라운드로 동기화 (보통 캐시와 동일).
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/character_action.dart';

typedef CachedCharacter = ({double x, double y, CharacterActionType action});

class CharacterCache {
  static String _key(String idolId) => 'character_pos_$idolId';

  Future<CachedCharacter?> read(String idolId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(idolId));
    if (raw == null) return null;
    final m = jsonDecode(raw) as Map<String, dynamic>;
    final x = (m['x'] as num?)?.toDouble();
    final y = (m['y'] as num?)?.toDouble();
    if (x == null || y == null) return null;
    final actionName = m['action'] as String?;
    final action = CharacterActionType.values.firstWhere(
      (e) => e.name == actionName,
      orElse: () => CharacterActionType.idle,
    );
    return (x: x, y: y, action: action);
  }

  Future<void> write(
    String idolId,
    double x,
    double y,
    CharacterActionType action,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(idolId),
      jsonEncode({'x': x, 'y': y, 'action': action.name}),
    );
  }
}
