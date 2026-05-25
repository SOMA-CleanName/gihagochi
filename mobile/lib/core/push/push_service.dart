/// FCM 푸시 초기화 + 토큰 등록 + 메시지 핸들러.
///
/// 백엔드의 `device_tokens` 테이블에 토큰 POST 필요 (features/notification에서 처리).
/// 여기서는 초기화 + 토큰 발급 + foreground 표시까지.
library;

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 백엔드에 토큰 등록할 콜백. features/notification에서 주입.
typedef TokenRegistrar = Future<void> Function(String token, String platform);

class PushService {
  PushService._();

  static final _messaging = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();
  static TokenRegistrar? _registrar;

  /// main.dart에서 Firebase.initializeApp() 이후 호출.
  static Future<void> init({TokenRegistrar? registrar}) async {
    _registrar = registrar;

    // 권한 요청 (iOS는 명시적, Android 13+도)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (kDebugMode) {
      debugPrint('[Push] permission=${settings.authorizationStatus}');
    }
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    await _setupLocalNotifications();

    // iOS foreground에서도 시스템 배너/사운드/뱃지 표시 — 기본은 silent.
    // foreground 메시지는 onMessage stream에도 들어와서 flutter_local_notifications로
    // 표시되지만, iOS 시스템 배너가 동시에 뜨는 게 사용자 기대치에 가까움.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // iOS는 APNs 토큰이 set된 후에야 FCM 토큰 발급 가능.
    // 시뮬레이터(iOS 16+)/실기기 모두 등록이 약간 늦어 race 발생 → 짧게 poll.
    // poll 실패 시 graceful skip — 권한 거부/Push entitlement 미설정 환경.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ok = await _waitForApnsToken();
      if (!ok) {
        if (kDebugMode) {
          debugPrint('[Push] APNS token timeout — FCM 토큰 발급 skip');
        }
        return;
      }
    }

    // 토큰 발급 + 등록
    final token = await _messaging.getToken();
    if (kDebugMode) {
      final preview = token == null ? 'null' : '${token.substring(0, 30)}... (len=${token.length})';
      debugPrint('[Push] FCM token: $preview');
    }
    if (token != null && _registrar != null) {
      try {
        await _registrar!(token, _platformName());
        if (kDebugMode) debugPrint('[Push] 백엔드 등록 완료');
      } catch (e) {
        if (kDebugMode) debugPrint('[Push] 백엔드 등록 실패 (silent): $e');
      }
    }

    // 토큰 갱신 시 재등록
    _messaging.onTokenRefresh.listen((newToken) async {
      if (kDebugMode) debugPrint('[Push] FCM token refreshed: ${newToken.substring(0, 30)}...');
      if (_registrar != null) await _registrar!(newToken, _platformName());
    });

    // foreground 메시지 → 로컬 알림으로 표시
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
  }

  static Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notif = message.notification;
    if (kDebugMode) {
      debugPrint('[Push] foreground 메시지: title="${notif?.title}" body="${notif?.body}"');
    }
    if (notif == null) return;

    await _local.show(
      notif.hashCode,
      notif.title,
      notif.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          '기본 알림',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }

  static String _platformName() {
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    return 'unknown';
  }

  /// iOS APNs 토큰이 set될 때까지 짧게 poll (최대 10초).
  /// `true` = 받음 / `false` = 타임아웃.
  static Future<bool> _waitForApnsToken() async {
    const interval = Duration(milliseconds: 500);
    const maxAttempts = 20; // 10초
    for (var i = 0; i < maxAttempts; i++) {
      final apns = await _messaging.getAPNSToken();
      if (apns != null) {
        if (kDebugMode) debugPrint('[Push] APNS token received (attempt ${i + 1})');
        return true;
      }
      await Future.delayed(interval);
    }
    return false;
  }
}
