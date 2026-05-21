/// F-001~F-006 auth 라우트 정의.
///
/// `core/router/app_router.dart`에서 import 후 spread:
///   import '../../features/auth/routes.dart';
///   routes: [..., ...authRoutes],
///
/// `/auth/*` 경로는 `core/auth/auth_guard.dart`의 `_publicRoutes`에도 등록되어야
/// 미로그인 상태에서 진입 가능.
library;

import 'package:go_router/go_router.dart';

import 'presentation/idol_pending_screen.dart';
import 'presentation/landing_screen.dart';
import 'presentation/signup_profile_screen.dart';
import 'presentation/signup_role_screen.dart';
import 'presentation/signup_terms_screen.dart';

final List<RouteBase> authRoutes = [
  GoRoute(
    path: '/auth/landing',
    builder: (context, state) => const LandingScreen(),
  ),
  GoRoute(
    path: '/auth/signup/role',
    builder: (context, state) => const SignupRoleScreen(),
  ),
  GoRoute(
    path: '/auth/signup/terms',
    builder: (context, state) => const SignupTermsScreen(),
  ),
  GoRoute(
    path: '/auth/signup/profile',
    builder: (context, state) => const SignupProfileScreen(),
  ),
  GoRoute(
    path: '/auth/idol-pending',
    builder: (context, state) => const IdolPendingScreen(),
  ),
];
