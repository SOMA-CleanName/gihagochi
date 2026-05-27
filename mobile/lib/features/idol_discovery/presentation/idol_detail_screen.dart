/// F-011 아이돌 상세 화면.
///
/// "응원하기" 버튼은 subscription 슬라이스의 controller 호출.
/// 액션 완료 후 상세 controller invalidate → fan_count / is_subscribed 자동 갱신.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/domain/auth_models.dart' show UserRole;
import '../../profile/application/my_profile_controller.dart';
import '../../subscription/application/subscription_controller.dart';
import '../application/idol_detail_controller.dart';

class IdolDetailScreen extends ConsumerWidget {
  const IdolDetailScreen({super.key, required this.idolId});

  final String idolId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(idolDetailControllerProvider(idolId));
    final subscriptionState = ref.watch(subscriptionControllerProvider);
    final theme = Theme.of(context);
    // 본인이 아이돌이면 응원 자체 불가 (정책 2026-05-27).
    final myProfileAsync = ref.watch(myProfileControllerProvider);
    final isViewerIdol = myProfileAsync.maybeWhen(
      data: (p) => p.role == UserRole.idol,
      orElse: () => false,
    );

    Future<void> handleToggle(bool currentlySubscribed) async {
      final notifier = ref.read(subscriptionControllerProvider.notifier);
      // 응원 토글: 현재 응원 중이면 취소, 아니면 시작.
      if (currentlySubscribed) {
        await notifier.unsubscribe(idolId);
      } else {
        await notifier.subscribe(idolId);
      }
      // 액션 결과(error/data) 반영 후 상세 정보 새로고침.
      final error = ref.read(subscriptionControllerProvider).asError;
      if (!context.mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('처리 실패: ${error.error}')),
        );
        return;
      }
      ref.invalidate(idolDetailControllerProvider(idolId));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('아이돌 상세')),
      body: state.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () =>
              ref.read(idolDetailControllerProvider(idolId).notifier).refresh(),
        ),
        data: (idol) {
          final isProcessing = subscriptionState.isLoading;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Avatar(
                  imageUrl: idol.thumbnailUrl,
                  size: 120,
                  fallbackText: idol.stageName,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  idol.stageName,
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '응원 팬 ${idol.fanCount}명',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if ((idol.bio ?? '').isNotEmpty) ...[
                Text('소개', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(idol.bio!, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 24),
              ],
              if (isViewerIdol)
                // 아이돌은 다른 아이돌을 응원할 수 없음.
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: theme.colorScheme.outline, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '아이돌 계정은 다른 아이돌을 응원할 수 없습니다.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isProcessing
                        ? null
                        : () => handleToggle(idol.isSubscribed),
                    child: Text(
                      isProcessing
                          ? '처리 중…'
                          : (idol.isSubscribed ? '응원 중' : '응원하기'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
