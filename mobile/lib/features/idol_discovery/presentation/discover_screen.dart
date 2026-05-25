/// F-008 / F-009 탐색 화면 — 검색바 + 무한 스크롤 리스트.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../application/idol_list_controller.dart';
import 'widgets/idol_card.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    // 리스트 하단 200px 이내 진입 시 다음 페이지 로드.
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(idolListControllerProvider.notifier).loadMore();
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(idolSearchQueryProvider.notifier).set(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(idolListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('아이돌 탐색'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onQueryChanged,
              decoration: const InputDecoration(
                hintText: '활동명 검색',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
      ),
      body: state.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () =>
              ref.read(idolListControllerProvider.notifier).refresh(),
        ),
        data: (data) {
          if (data.items.isEmpty) {
            final query = ref.read(idolSearchQueryProvider);
            return EmptyView(
              message: query.isEmpty
                  ? '아직 활성 아이돌이 없습니다.'
                  : '"$query" 검색 결과가 없습니다.',
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(idolListControllerProvider.notifier).refresh(),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: data.items.length + (data.isLoadingMore ? 1 : 0),
              itemBuilder: (_, i) {
                if (i >= data.items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final item = data.items[i];
                return IdolCard(
                  item: item,
                  onTap: () => context.push('/discover/${item.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
