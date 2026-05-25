/// F-029 / F-031 notification — 백엔드 API 호출.
library;

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/dio_client.dart';
import '../domain/notification_models.dart';

part 'notification_repository.g.dart';

@riverpod
NotificationRepository notificationRepository(Ref ref) {
  return NotificationRepository(dio: ref.watch(dioProvider));
}

class NotificationRepository {
  NotificationRepository({required this.dio});

  final Dio dio;

  // ============================================================
  // device tokens
  // ============================================================

  /// POST /notification/device-tokens — 등록 (멱등, 백엔드가 reassign 처리).
  /// 실패해도 throw 안 함 (앱 동작 차단 X) — 호출 측이 try/catch 없이 사용.
  Future<void> registerDeviceToken(String token, String platform) async {
    await dio.post(
      '/notification/device-tokens',
      data: {'token': token, 'platform': platform},
    );
  }

  /// DELETE /notification/device-tokens?token=... — 해제 (멱등).
  Future<void> unregisterDeviceToken(String token) async {
    await dio.delete(
      '/notification/device-tokens',
      queryParameters: {'token': token},
    );
  }

  // ============================================================
  // prefs
  // ============================================================

  /// GET /notification/prefs — 조회 (백엔드 lazy create default).
  Future<NotificationPrefs> fetchPrefs() async {
    final res = await dio.get('/notification/prefs');
    return NotificationPrefs.fromJson(res.data as Map<String, dynamic>);
  }

  /// PATCH /notification/prefs — 부분 업데이트.
  Future<NotificationPrefs> updatePrefs(NotificationPrefsPatch patch) async {
    final res = await dio.patch(
      '/notification/prefs',
      data: patch.toJson(),
    );
    return NotificationPrefs.fromJson(res.data as Map<String, dynamic>);
  }
}
