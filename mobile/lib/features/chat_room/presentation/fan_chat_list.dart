/// F-007(data) / F-014 — profile 의 `chatListSlotProvider` 를 override 하는 위젯.
///
/// `main.dart` 의 `ProviderScope.overrides` 에서 등록되어 `/main` 채팅 탭에 표시.
/// 자체 Scaffold + AppBar 가짐 (status bar 침범 방지). FAB은 BottomNav '탐색' 탭으로 대체 → 제거.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../application/chat_list_controller.dart';
import 'widgets/chat_room_card_tile.dart';

class FanChatList extends ConsumerWidget {
  const FanChatList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(chatListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('내 채팅')),
      body: RefreshIndicator(
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
              itemCount: cards.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 88),
              itemBuilder: (_, i) => ChatRoomCardTile(card: cards[i]),
            );
          },
        ),
      ),
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
                  '하단 "탐색" 탭에서 응원할 아이돌을 찾아보세요.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF757575),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
