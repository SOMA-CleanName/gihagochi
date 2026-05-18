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

    // 토큰 발급 + 등록
    final token = await _messaging.getToken();
    if (token != null && _registrar != null) {
      await _registrar!(token, _platformName());
    }

    // 토큰 갱신 시 재등록
    _messaging.onTokenRefresh.listen((newToken) async {
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
}
