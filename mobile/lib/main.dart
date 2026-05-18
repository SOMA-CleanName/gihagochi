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
import 'core/push/push_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

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

  // 푸시 — features/notification에서 TokenRegistrar 주입 가능.
  await PushService.init();

  // Sentry로 감싼 runApp. DSN 없으면 init 자체가 no-op.
  await SentryFlutter.init(
    (options) {
      options.dsn = Env.sentryDsn;
      options.environment = Env.env;
      options.tracesSampleRate = Env.isDev ? 1.0 : 0.1;
      options.sendDefaultPii = false;
    },
    appRunner: () => runApp(
      const ProviderScope(child: _GihagochiApp()),
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
