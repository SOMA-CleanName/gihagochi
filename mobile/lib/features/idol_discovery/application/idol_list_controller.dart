/// F-008 / F-009 / F-010 idol_discovery — 리스트 controller.
///
/// 검색어 변경 시 page=1부터 자동 reload.
/// loadMore() 호출 시 다음 페이지를 items 끝에 append.
library;

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/idol_repository.dart';
import '../domain/idol_models.dart';

part 'idol_list_controller.g.dart';

/// 검색어 — UI의 검색바가 갱신. controller가 watch.
@riverpod
class IdolSearchQuery extends _$IdolSearchQuery {
  @override
  String build() => '';

  void set(String value) {
    state = value;
  }
}

/// 리스트 상태. items 누적 + 페이지 + hasMore + isLoadingMore.
@immutable
class IdolListState {
  const IdolListState({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.isLoadingMore,
  });

  final List<IdolListItem> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  IdolListState copyWith({
    List<IdolListItem>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return IdolListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

@riverpod
class IdolListController extends _$IdolListController {
  static const _pageSize = 20;

  @override
  Future<IdolListState> build() async {
    // 검색어 변경 시 자동 invalidate → page=1부터 재조회.
    final query = ref.watch(idolSearchQueryProvider);
    final repo = ref.read(idolRepositoryProvider);
    final first = await repo.fetchList(query: query, page: 1, pageSize: _pageSize);
    return IdolListState(
      items: first.items,
      page: 1,
      hasMore: first.hasMore,
      isLoadingMore: false,
    );
  }

  /// 무한 스크롤 — 다음 페이지를 fetch 후 items 끝에 append.
  /// hasMore=false 거나 이미 loading 중이면 noop.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) {
      return;
    }
    state = AsyncValue.data(current.copyWith(isLoadingMore: true));

    final query = ref.read(idolSearchQueryProvider);
    final repo = ref.read(idolRepositoryProvider);
    try {
      final next = await repo.fetchList(
        query: query,
        page: current.page + 1,
        pageSize: _pageSize,
      );
      state = AsyncValue.data(
        current.copyWith(
          items: [...current.items, ...next.items],
          page: current.page + 1,
          hasMore: next.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e, st) {
      // 무한 스크롤 실패는 전체 상태를 깨뜨리지 말고 isLoadingMore 만 해제.
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
