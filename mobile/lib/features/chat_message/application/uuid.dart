/// 클라이언트 멱등성용 UUID v4 생성기.
///
/// `uuid` 패키지 추가 회피 — 1회용 함수라 dart:math 만으로 충분.
library;

import 'dart:math';

String generateUuidV4() {
  final rng = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  // RFC 4122 § 4.4 — version 4 표시.
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int b) => b.toRadixString(16).padLeft(2, '0');
  final h = bytes.map(hex).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20, 32)}';
}
