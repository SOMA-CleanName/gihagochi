/// F-029 — 푸시 서비스 초기화 + 토큰 등록 wiring.
///
/// PushService.init은 ProviderScope 이후에 호출돼야 ref.read로 repository를 얻을 수 있음.
/// main.dart에서 `_GihagochiApp`을 `PushInitializer`로 감싸 사용.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/push/push_service.dart';
import '../data/notification_repository.dart';

class PushInitializer extends ConsumerStatefulWidget {
  const PushInitializer({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushInitializer> createState() => _PushInitializerState();
}

class _PushInitializerState extends ConsumerState<PushInitializer> {
  @override
  void initState() {
    super.initState();
    // initState는 sync — 비동기 init은 microtask로 위임.
    Future.microtask(_initPush);
  }

  Future<void> _initPush() async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      await PushService.init(
        registrar: (token, platform) async {
          try {
            await repo.registerDeviceToken(token, platform);
          } catch (e) {
            // 등록 실패는 silent — 앱 동작 차단 X.
            if (kDebugMode) debugPrint('[push] 토큰 등록 실패: $e');
          }
        },
      );
    } catch (e) {
      // 시뮬레이터/Push entitlement 미설정 환경에선 APNS 부재로 throw — graceful degrade.
      if (kDebugMode) debugPrint('[push] init 실패 (FCM 토큰 비활성): $e');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
