/// F-028 — 마이페이지 (`/my`). 팬/아이돌 분기 표시.
///
/// 섹션:
/// - 프로필 카드
/// - (아이돌) "메시지 발행 준비 중" 배너
/// - (팬) 응원 중 슬롯 (subscription override 대상)
/// - 알림 설정 슬롯 (notification override 대상)
/// - 계정·보안 진입
/// - 약관/개인정보/고객센터 진입
/// - 로그아웃
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/domain/auth_models.dart' show UserRole;
import '../application/my_profile_controller.dart';
import '../application/slot_providers.dart';
import '../data/profile_repository.dart';
import 'widgets/profile_card.dart';

class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfile = ref.watch(myProfileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('마이페이지')),
      body: asyncProfile.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () =>
              ref.read(myProfileControllerProvider.notifier).refresh(),
        ),
        data: (profile) {
          final isIdol = profile.role == UserRole.idol;
          return ListView(
            children: [
              ProfileCard(profile: profile),
              if (isIdol) const _IdolPendingBanner(),
              const Divider(height: 1),
              if (!isIdol) ...[
                const _SectionHeader(title: '응원 중인 아이돌'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ref.watch(subscriptionListSlotProvider),
                ),
                const SizedBox(height: 8),
              ],
              const _SectionHeader(title: '알림'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ref.watch(notificationSettingsSlotProvider),
              ),
              const SizedBox(height: 8),
              const _SectionHeader(title: '계정·약관'),
              ListTile(
                leading: const Icon(Icons.security_outlined),
                title: const Text('계정·보안'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/my/account'),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('이용약관'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/my/legal/tos'),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('개인정보 처리방침'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/my/legal/privacy'),
              ),
              ListTile(
                leading: const Icon(Icons.support_agent_outlined),
                title: const Text('고객센터'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/my/legal/contact'),
              ),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  '로그아웃',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () => _confirmLogout(context, ref),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    // Supabase signOut만으로 충분 — auth_guard가 /auth/landing으로 자동 라우팅.
    await ref.read(profileRepositoryProvider).supabase.auth.signOut();
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _IdolPendingBanner extends StatelessWidget {
  const _IdolPendingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '메시지 발행 기능은 준비 중입니다.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
