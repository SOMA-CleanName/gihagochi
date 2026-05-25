/// F-007 / F-028 / F-030 / F-032 / F-034 — profile 라우트 정의.
///
/// `core/router/app_router.dart`에서 spread:
///   import '../../features/profile/routes.dart';
///   routes: [..., ...profileRoutes],
library;

import 'package:go_router/go_router.dart';

import 'presentation/account_page.dart';
import 'presentation/edit_fan_page.dart';
import 'presentation/edit_idol_page.dart';
import 'presentation/legal_pages.dart';
import 'presentation/main_screen.dart';
import 'presentation/my_page.dart';

final List<RouteBase> profileRoutes = [
  GoRoute(path: '/main', builder: (_, __) => const MainScreen()),
  GoRoute(path: '/my', builder: (_, __) => const MyPage()),
  GoRoute(path: '/my/edit/fan', builder: (_, __) => const EditFanPage()),
  GoRoute(path: '/my/edit/idol', builder: (_, __) => const EditIdolPage()),
  GoRoute(path: '/my/account', builder: (_, __) => const AccountPage()),
  GoRoute(path: '/my/legal/tos', builder: (_, __) => const TosPage()),
  GoRoute(path: '/my/legal/privacy', builder: (_, __) => const PrivacyPage()),
  GoRoute(path: '/my/legal/contact', builder: (_, __) => const ContactPage()),
];
