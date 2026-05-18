/// `flutter_secure_storage` 래퍼.
///
/// Supabase 세션은 supabase_flutter가 SharedPreferences로 자체 관리.
/// 이 클래스는 **민감 토큰** (예: 서드파티 API 키, refresh token 별도 관리 필요 시)용.
///
/// 사용:
///   await SecureStorage.write('fcm_token', token);
///   final v = await SecureStorage.read('fcm_token');
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<String?> read(String key) => _storage.read(key: key);

  static Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  static Future<void> delete(String key) => _storage.delete(key: key);

  static Future<void> deleteAll() => _storage.deleteAll();
}
