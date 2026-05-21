/// F-002 아이돌 승인 대기 화면.
///
/// 표시 상태:
/// - pending: "심사 중" + 신청일
/// - rejected: 사유 + "재신청" 버튼
/// - approved: cold-start까지 stale이면 강제 새로고침
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/loading_view.dart';
import '../application/auth_controller.dart';
import '../domain/auth_models.dart';

class IdolPendingScreen extends ConsumerWidget {
  const IdolPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('아이돌 신청')),
      body: SafeArea(
        child: me.when(
          loading: () => const LoadingView(),
          error: (e, _) => Center(child: Text('상태를 불러올 수 없습니다: $e')),
          data: (data) {
            final app = data?.latestIdolApplication;
            if (app == null) {
              // 신청 자체가 없으면 안 들어와야 할 화면.
              return const Center(child: Text('신청 내역이 없습니다.'));
            }
            return _Body(application: app, onRefresh: () => ref
                .read(authControllerProvider.notifier)
                .refresh());
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.application, required this.onRefresh});

  final IdolApplicationSummary application;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final created = DateFormat('yyyy.MM.dd HH:mm').format(application.createdAt.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title(application.status),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text('활동명: ${application.stageName}'),
          Text('신청일: $created'),
          const SizedBox(height: 24),
          Text(_description(application.status)),
          if (application.status == SignupApplicationStatus.rejected &&
              application.rejectionReason != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '거절 사유',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(application.rejectionReason!),
                  ],
                ),
              ),
            ),
          ],
          const Spacer(),
          if (application.status == SignupApplicationStatus.rejected)
            FilledButton(
              onPressed: () => context.go('/auth/signup/role'),
              child: const Text('재신청'),
            ),
          TextButton(
            onPressed: onRefresh,
            child: const Text('상태 다시 확인'),
          ),
        ],
      ),
    );
  }

  String _title(SignupApplicationStatus s) => switch (s) {
        SignupApplicationStatus.pending => '심사 중',
        SignupApplicationStatus.approved => '승인됨',
        SignupApplicationStatus.rejected => '거절됨',
        SignupApplicationStatus.withdrawn => '신청 취소됨',
      };

  String _description(SignupApplicationStatus s) => switch (s) {
        SignupApplicationStatus.pending =>
          '관리자가 신청을 검토 중입니다. 승인되면 아이돌 기능이 활성화됩니다. 그동안 팬 기능은 그대로 사용할 수 있어요.',
        SignupApplicationStatus.approved =>
          '승인되었습니다. 앱을 다시 시작하면 아이돌 화면으로 진입합니다.',
        SignupApplicationStatus.rejected =>
          '아래 사유를 확인하고 재신청할 수 있어요.',
        SignupApplicationStatus.withdrawn => '이 신청은 취소되었습니다.',
      };
}
