/// JSON key 케이스 변환 유틸.
///
/// `camelToSnake`: `userName` → `user_name` (idempotent: `user_name` → `user_name`)
/// `snakeToCamel`: `user_name` → `userName` (idempotent: `userName` → `userName`)
/// `convertKeys`: Map/List를 재귀적으로 traverse하며 모든 키를 변환.
///
/// 변환은 string key만 — value(DateTime, num, bool)는 그대로.
library;

/// camelCase → snake_case. 이미 snake면 그대로.
/// 규칙: 대문자 앞에 `_`. 첫 글자는 변환 안 함 (leading `_` 방지).
String camelToSnake(String input) {
  if (input.isEmpty) return input;
  final buf = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    final ch = input[i];
    final isUpper = ch.codeUnitAt(0) >= 0x41 && ch.codeUnitAt(0) <= 0x5A;
    if (isUpper && i > 0) buf.write('_');
    buf.write(ch.toLowerCase());
  }
  return buf.toString();
}

/// snake_case → camelCase. 이미 camel/단일 단어면 그대로.
/// 규칙: `_` 다음 글자 대문자화 + `_` 제거. trailing/leading `_`는 보존하지 않음 (모두 제거).
String snakeToCamel(String input) {
  if (input.isEmpty || !input.contains('_')) return input;
  final parts = input.split('_');
  final buf = StringBuffer(parts.first);
  for (var i = 1; i < parts.length; i++) {
    final p = parts[i];
    if (p.isEmpty) continue;
    buf
      ..write(p[0].toUpperCase())
      ..write(p.substring(1));
  }
  return buf.toString();
}

/// dynamic JSON 값을 재귀 순회하며 Map의 키만 [transform] 적용.
/// List 안 Map도 처리. 그 외(String, num, bool, null, DateTime)는 그대로.
dynamic convertKeys(dynamic value, String Function(String) transform) {
  if (value is Map) {
    final out = <String, dynamic>{};
    value.forEach((k, v) {
      final newKey = k is String ? transform(k) : k.toString();
      out[newKey] = convertKeys(v, transform);
    });
    return out;
  }
  if (value is List) {
    return value.map((e) => convertKeys(e, transform)).toList();
  }
  return value;
}
