/// F-007(data) / F-014 — profile 의 `chatListSlotProvider` 를 override 하는 위젯.
///
/// `main.dart` 의 `ProviderScope.overrides` 에서 등록되어 `/main` 에 표시됨.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../application/chat_list_controller.dart';
import 'widgets/chat_room_card_tile.dart';

class FanChatList extends ConsumerWidget {
  const FanChatList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(chatListControllerProvider);

    final list = RefreshIndicator(
      onRefresh: () => ref.read(chatListControllerProvider.notifier).refresh(),
      child: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () =>
              ref.read(chatListControllerProvider.notifier).refresh(),
        ),
        data: (cards) {
          if (cards.isEmpty) return const _EmptyChatRoomList();
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            // 마지막 카드 아래 FAB과 겹치지 않게 여유.
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 88),
            itemBuilder: (_, i) => ChatRoomCardTile(card: cards[i]),
          );
        },
      ),
    );

    return Stack(
      children: [
        Positioned.fill(child: list),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'fan_discover_fab',
            onPressed: () => _goDiscover(context),
            icon: const Icon(Icons.search),
            label: const Text('아이돌 찾기'),
          ),
        ),
      ],
    );
  }
}

void _goDiscover(BuildContext context) {
  try {
    context.push('/discover');
  } catch (_) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('아이돌 탐색을 열 수 없습니다.')),
    );
  }
}

class _EmptyChatRoomList extends StatelessWidget {
  const _EmptyChatRoomList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite_outline,
                  size: 56,
                  color: Color(0xFFBDBDBD),
                ),
                const SizedBox(height: 16),
                Text(
                  '응원 중인 아이돌이 없어요',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '좋아하는 아이돌을 찾아 응원을 시작해보세요.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF757575),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('아이돌 추가하기'),
                  onPressed: () => _goDiscover(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

}
