/// F-031 알림 설정 라우트.
///
/// `core/router/app_router.dart`에서 import 후 spread:
///   import '../../features/notification/routes.dart';
///   routes: [..., ...notificationRoutes],
library;

import 'package:go_router/go_router.dart';

import 'presentation/notification_settings_screen.dart';

final List<RouteBase> notificationRoutes = [
  GoRoute(
    path: '/settings/notifications',
    builder: (context, state) => const NotificationSettingsScreen(),
  ),
];
