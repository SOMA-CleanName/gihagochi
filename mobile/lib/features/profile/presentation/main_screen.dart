/// 메인 화면 (`/main`) — 하단 BottomNavigationBar 3 탭.
///
/// - 탐색: idol_discovery의 `DiscoverScreen`
/// - 채팅: 팬은 `chatListSlotProvider`(채팅방 리스트), 아이돌은 본인 채팅방 진입 화면
/// - 마이: profile의 `MyPage`
///
/// 라우트는 그대로(`/main`). 탭 전환은 `IndexedStack`으로 stack 보존.
/// 각 화면이 자체 `Scaffold`를 가지면 그대로 중첩 (Flutter 허용).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/domain/auth_models.dart' show UserRole;
import '../../idol_discovery/presentation/discover_screen.dart';
import '../application/my_profile_controller.dart';
import '../application/slot_providers.dart';
import 'my_page.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _tabIndex = 1; // 진입 시 채팅 탭부터

  @override
  Widget build(BuildContext context) {
    final asyncProfile = ref.watch(myProfileControllerProvider);
    return asyncProfile.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (e, _) => Scaffold(
        body: ErrorView(
          error: e,
          onRetry: () =>
              ref.read(myProfileControllerProvider.notifier).refresh(),
        ),
      ),
      data: (profile) {
        final isIdol = profile.role == UserRole.idol;
        // 채팅 탭 body 결정.
        // - 팬: 기존 chatListSlotProvider (chat_room override) → 채팅방 리스트
        // - 아이돌: 본인 채팅방 진입 카드 (탭하면 /chat/<본인 id>로 push)
        final chatBody = isIdol
            ? _IdolSelfChatTab(idolId: profile.id)
            : ref.watch(chatListSlotProvider);

        return Scaffold(
          body: IndexedStack(
            index: _tabIndex,
            children: [
              const DiscoverScreen(),
              chatBody,
              const MyPage(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tabIndex,
            onDestinationSelected: (i) => setState(() => _tabIndex = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search),
                label: '탐색',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: '채팅',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: '마이',
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 아이돌 본인 채팅 탭 — 본인 채팅방 1개 진입 카드.
class _IdolSelfChatTab extends StatelessWidget {
  const _IdolSelfChatTab({required this.idolId});
  final String idolId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 채팅방')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.3),
                      AppColors.tertiary.withValues(alpha: 0.3),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.forum_outlined,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('내 채팅방', style: AppTextStyles.titleLg),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '팬들에게 메시지를 발행하고\n답장을 확인할 수 있어요.',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: '채팅방 들어가기',
                onPressed: () => context.push('/chat/$idolId'),
                icon: Icons.arrow_forward,
                glow: true,
                fullWidth: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
