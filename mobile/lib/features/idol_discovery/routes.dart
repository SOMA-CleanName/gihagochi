/// F-008 ~ F-011 idol_discovery 라우트 정의.
///
/// `core/router/app_router.dart`에서 import 후 spread:
///   import '../../features/idol_discovery/routes.dart';
///   routes: [..., ...idolDiscoveryRoutes],
library;

import 'package:go_router/go_router.dart';

import 'presentation/discover_screen.dart';
import 'presentation/idol_detail_screen.dart';

final List<RouteBase> idolDiscoveryRoutes = [
  GoRoute(
    path: '/discover',
    builder: (context, state) => const DiscoverScreen(),
    routes: [
      GoRoute(
        path: ':idolId',
        builder: (context, state) {
          final idolId = state.pathParameters['idolId']!;
          return IdolDetailScreen(idolId: idolId);
        },
      ),
    ],
  ),
];
