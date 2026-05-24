/// go_router redirect 가드 — 로그인 여부에 따라 경로 전환.
///
/// 사용 (`core/router/app_router.dart`에서):
///   GoRouter(
///     redirect: (context, state) => authGuard(ref, state),
///     ...
///   )
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_service.dart';

/// 보호되지 않는 (인증 없이 접근 가능한) 경로 prefix.
/// 새 인증 관련 화면 추가 시 여기에 등록.
const _publicRoutes = <String>{
  '/splash',
  '/auth', // F-001~F-006: /auth/landing, /auth/signup/*, /auth/idol-pending
};

/// null 반환 = redirect 없음. 경로 문자열 반환 = 그쪽으로 이동.
String? authGuard(Ref ref, GoRouterState state) {
  // currentUserProvider는 authStateChangesProvider(StreamProvider)에 의존하는데,
  // Stream invalidation이 microtask로 지연되어 refresh notifier가 즉시 부르는 redirect
  // 시점엔 stale null이 반환됨. supabase 내부 currentUser는 SIGNED_IN 발화 전 이미
  // set되므로 동기 read가 안전 — race 회피.
  final user = ref.read(supabaseProvider).auth.currentUser;
  final loc = state.matchedLocation;
  final isPublic = _publicRoutes.any((p) => loc.startsWith(p));

  // 미로그인 + 보호 경로 → auth 랜딩으로
  if (user == null && !isPublic) {
    return '/auth/landing';
  }

  // 로그인 + 인증 화면 → 팬 메인으로
  // F-007 메인 화면 라우트. 등록은 features/profile.
  if (user != null && isPublic) {
    return '/main';
  }

  return null;
}
