/// dev 전용 floating debug 패널.
///
/// 우측 하단 FAB → tap → BottomSheet에 quick action들.
/// 시뮬레이터에서 라우트 직접 입력 없이 빠른 nav / 디버깅 용도.
///
/// 노출 조건 (3중 가드):
///   1. `kDebugMode` — release 빌드 tree-shaking
///   2. `Env.isDev` — prod 환경에선 OFF
///   3. `Env.devQuickLoginEmail != null` — dev 셋업 안 한 사용자엔 노출 X
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_service.dart';
import '../config/env.dart';
import '../router/app_router.dart' show rootNavigatorKey;

class DevOverlay extends ConsumerWidget {
  const DevOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_shouldShow) return child;

    return Stack(
      children: [
        child,
        const Positioned(
          right: 16,
          bottom: 80, // BottomNav과 안 겹치게
          child: _DevFab(),
        ),
      ],
    );
  }

  bool get _shouldShow {
    if (!kDebugMode) return false;
    if (!Env.isDev) return false;
    return Env.devQuickLoginEmail != null;
  }
}

class _DevFab extends ConsumerWidget {
  const _DevFab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.small(
      heroTag: 'dev-overlay-fab',
      backgroundColor: Colors.amber.shade700,
      foregroundColor: Colors.white,
      onPressed: () => _showMenu(context, ref),
      child: const Icon(Icons.bug_report, size: 20),
    );
  }

  Future<void> _showMenu(BuildContext _, WidgetRef ref) {
    // MaterialApp.router builder의 context는 Navigator 위쪽 → showModalBottomSheet 실패.
    // GoRouter의 navigatorKey context 사용 (Navigator scope 안).
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return Future.value();

    final user = ref.read(supabaseProvider).auth.currentUser;
    final userId = user?.id;

    return showModalBottomSheet<void>(
      context: navContext,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.bug_report, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    'DEV ONLY — 디버그 메뉴',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'user: ${userId ?? '비로그인'}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF757575)),
              ),
              const Divider(height: 24),

              // 내 채팅방 진입 (아이돌 본인 채팅방 = 자기 idolId)
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('내 채팅방 진입 (idol)'),
                subtitle: const Text('/chat/<현재 사용자 id>'),
                enabled: userId != null,
                onTap: userId == null
                    ? null
                    : () {
                        Navigator.of(sheetContext).pop();
                        rootNavigatorKey.currentContext?.push('/chat/$userId');
                      },
              ),

              // 채팅방 진입 (임의 idolId 입력)
              ListTile(
                leading: const Icon(Icons.input),
                title: const Text('채팅방 진입 (idolId 직접 입력)'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _showIdolIdDialog();
                },
              ),

              // 라우트 직접 입력
              ListTile(
                leading: const Icon(Icons.alt_route),
                title: const Text('경로 직접 입력'),
                subtitle: const Text('/discover, /settings/notifications 등'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _showRouteDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showIdolIdDialog() async {
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return;
    final controller = TextEditingController();
    final id = await showDialog<String>(
      context: navContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('채팅방 진입'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'idolId (uuid)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('진입'),
          ),
        ],
      ),
    );
    if (id != null && id.isNotEmpty) {
      rootNavigatorKey.currentContext?.push('/chat/$id');
    }
  }

  Future<void> _showRouteDialog() async {
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return;
    final controller = TextEditingController(text: '/');
    final route = await showDialog<String>(
      context: navContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('경로 직접 이동'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '/discover'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('이동'),
          ),
        ],
      ),
    );
    if (route != null && route.isNotEmpty) {
      rootNavigatorKey.currentContext?.push(route);
    }
  }
}
