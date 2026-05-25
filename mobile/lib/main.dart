/// 앱 부트스트랩.
///
/// 순서:
/// 1. WidgetsFlutterBinding
/// 2. Env.init (dotenv 로드)
/// 3. Sentry init (DSN 있으면)
/// 4. Firebase init (FCM 사용 시. google-services.json/GoogleService-Info.plist 필요)
/// 5. Supabase init
/// 6. PushService init
/// 7. ProviderScope + runApp
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
// 피처 슬롯 override — 새 피처가 다른 피처의 슬롯을 채울 때 여기에 1줄씩 추가.
import 'features/chat_room/application/slot_providers.dart' as chat_slots;
import 'features/chat_room/presentation/fan_chat_list.dart';
import 'features/gift/integration/gift_menu_action.dart';
import 'features/notification/presentation/notification_settings_entry.dart';
import 'features/notification/presentation/push_initializer.dart';
import 'features/profile/application/slot_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Env.init();
  Env.assertRequired();

  // Firebase — google-services.json/GoogleService-Info.plist 필요.
  // 미설치 환경에선 try/catch로 graceful degrade.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[main] Firebase init 실패 (FCM 비활성): $e');
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    debug: Env.isDev,
  );

  // 푸시 init은 ProviderScope 이후에 호출돼야 ref.read로 repository 얻을 수 있음 →
  // features/notification/presentation/push_initializer.dart가 ProviderScope 내부에서 호출.

  // Sentry로 감싼 runApp. DSN 없으면 init 자체가 no-op.
  await SentryFlutter.init(
    (options) {
      options.dsn = Env.sentryDsn;
      options.environment = Env.env;
      options.tracesSampleRate = Env.isDev ? 1.0 : 0.1;
      options.sendDefaultPii = false;
    },
    appRunner: () => runApp(
      ProviderScope(
        overrides: [
          // chat_room 이 profile 의 채팅방 리스트 슬롯을 채움.
          chatListSlotProvider.overrideWith((ref) => const FanChatList()),
          // notification 이 profile 마이페이지의 "알림 설정" 슬롯을 채움.
          notificationSettingsSlotProvider.overrideWith(
            (ref) => const NotificationSettingsEntry(),
          ),
          // gift 가 chat_room 채팅방 메뉴에 "선물하기" 액션 추가.
          chat_slots.chatRoomMenuActionsProvider.overrideWith(
            (ref) => [giftMenuAction()],
          ),
        ],
        // PushInitializer: ProviderScope 내부에서 FCM 토큰 발급 + 백엔드 등록.
        child: const PushInitializer(child: _GihagochiApp()),
      ),
    ),
  );
}

class _GihagochiApp extends ConsumerWidget {
  const _GihagochiApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'gihagochi',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
