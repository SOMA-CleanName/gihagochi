/// go_router 셋업.
///
/// 각 피처의 routes.dart에서 `List<RouteBase>` export → 여기서 import 후 합산.
/// Dart는 동적 파일 시스템 import가 없어서 백엔드처럼 100% auto는 안 됨.
/// 새 피처 추가 시 1줄만 더하면 됨 (`...newFeatureRoutes`).
///
/// 인증 가드는 `auth_guard.dart` 사용.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/auth_guard.dart';
import '../auth/auth_service.dart';
// 피처 라우트 import — 새 피처 추가 시 여기에 한 줄 추가.
import '../../features/auth/routes.dart';
// import '../../features/chat_room/routes.dart';
// ...

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // riverpod 3에서 provider.stream 제거 — supabase auth stream 직접 사용.
  final supabase = ref.watch(supabaseProvider);
  final refreshNotifier = _GoRouterRefreshStream(
    supabase.auth.onAuthStateChange,
  );
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) => authGuard(ref, state),
    routes: [
      // 임시 home — 실제 피처는 features/<폴더>/routes.dart에서 합산.
      GoRoute(
        path: '/',
        builder: (context, state) => const _PlaceholderScreen(label: '홈'),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const _PlaceholderScreen(label: '로그인'),
      ),
      // 새 피처 추가 시: `...authRoutes,` 처럼 spread
      ...authRoutes,
      // ...chatRoomRoutes,
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('경로 없음: ${state.matchedLocation}')),
    ),
  );
}

/// Stream을 Listenable로 어댑트. go_router refresh 트리거.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(child: Text('$label — 피처 미구현')),
    );
  }
}
