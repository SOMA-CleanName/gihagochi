/// F-XXX 라우트 정의.
///
/// `core/router/app_router.dart`에서 import 후 spread:
///   import '../../features/<폴더>/routes.dart';
///   routes: [..., ...templateRoutes],
library;

import 'package:go_router/go_router.dart';

import 'presentation/template_screen.dart';

final List<RouteBase> templateRoutes = [
  GoRoute(
    path: '/template',
    builder: (context, state) => const TemplateScreen(),
  ),
];
