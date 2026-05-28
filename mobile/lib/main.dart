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
import 'core/dev/dev_overlay.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_background.dart';
// 피처 슬롯 override — 새 피처가 다른 피처의 슬롯을 채울 때 여기에 1줄씩 추가.
import 'features/character/presentation/room_canvas.dart';
import 'features/chat_message/presentation/message_input.dart';
import 'features/chat_message/presentation/message_list.dart';
import 'features/chat_room/application/slot_providers.dart' as chat_slots;
import 'features/chat_room/presentation/fan_chat_list.dart';
import 'features/notification/presentation/notification_settings_entry.dart';
import 'features/notification/presentation/push_initializer.dart';
import 'features/profile/application/slot_providers.dart';
import 'features/subscription/integration/unsubscribe_menu_action.dart';

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
          // 채팅방 ⋮ 메뉴 — 본인이 fan일 때 호출되는 액션들.
          // 정책 2026-05-27: 선물은 입력창 좌측으로 이동 (메뉴에서 제거).
          chat_slots.chatRoomMenuActionsProvider.overrideWith(
            (ref) => [unsubscribeMenuAction(ref)],
          ),
          // chat_message 가 chat_room 의 메시지/입력창 슬롯을 채움.
          // (character.RoomCanvas가 직접 import해서 채팅 카드 안에 끼우므로
          //  chat_room의 slot은 사용 안 되지만 호환성 위해 유지.)
          chat_slots.chatMessageListSlotProvider
              .overrideWith((ref, idolId) => MessageList(idolId: idolId)),
          chat_slots.chatMessageInputSlotProvider
              .overrideWith((ref, idolId) => MessageInput(idolId: idolId)),
          // character 가 chat_room 의 캐릭터 슬롯에 풀스크린 RoomCanvas 위임.
          // RoomCanvas가 방+캐릭터+하단 반투명 채팅 카드까지 자체 렌더.
          chat_slots.chatRoomCharacterSlotProvider
              .overrideWith((ref, idolId) => RoomCanvas(idolId: idolId)),
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
      theme: AppTheme.theme,
      // 정책 2026-05-27: 네온 다크 단일 테마 — themeMode 강제 dark.
      darkTheme: AppTheme.theme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      // DevOverlay: kDebugMode + Env.isDev + .env DEV_QUICK_LOGIN 설정 시
      // 우측 하단에 floating debug FAB 노출. release 빌드 tree-shaken.
      builder: (context, child) => AppBackground(
        child: DevOverlay(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
