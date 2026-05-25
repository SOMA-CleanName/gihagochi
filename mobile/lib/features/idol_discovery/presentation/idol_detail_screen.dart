/// F-011 아이돌 상세 화면.
///
/// "응원하기" 버튼은 placeholder. subscription 슬라이스 합류 시 실제 액션 연결.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../application/idol_detail_controller.dart';

class IdolDetailScreen extends ConsumerWidget {
  const IdolDetailScreen({super.key, required this.idolId});

  final String idolId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(idolDetailControllerProvider(idolId));
    final theme = Theme.of(context);

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
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  // subscription 슬라이스 합류 전 placeholder.
                  // 본인이 아이돌 본인이면 백엔드가 is_subscribed=false로 반환하므로
                  // 응원 가능처럼 보일 수 있음 → 추후 본인 비교 로직 추가.
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('응원 기능은 준비 중입니다.')),
                    );
                  },
                  child: Text(idol.isSubscribed ? '응원 중' : '응원하기'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
