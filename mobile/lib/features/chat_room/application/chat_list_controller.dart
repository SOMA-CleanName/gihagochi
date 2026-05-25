/// F-007(data) / F-014 — 채널 리스트 상태.
///
/// chat_message 가 머지된 뒤 broadcast hook 이 `invalidateSelf` 호출하면
/// 자동 재조회로 카드가 갱신됨.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/chat_room_repository.dart';
import '../domain/chat_room_models.dart';

part 'chat_list_controller.g.dart';

@riverpod
class ChatListController extends _$ChatListController {
  @override
  Future<List<ChatRoomCard>> build() async {
    return ref.watch(chatRoomRepositoryProvider).fetchChannelList();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// 채팅방 진입 시 활성 subscription 검증 — 단발 fetch.
@riverpod
Future<bool> isActiveSubscription(Ref ref, String idolId) {
  return ref.watch(chatRoomRepositoryProvider).isActiveSubscription(idolId);
}

/// AppBar 용 아이돌 헤더 — 채팅방 화면 진입 시 1회 fetch.
@riverpod
Future<IdolHeader?> idolHeader(Ref ref, String idolId) {
  return ref.watch(chatRoomRepositoryProvider).fetchIdolHeader(idolId);
}
