/// F-007(data) / F-014 — 채널 리스트 상태.
///
/// chat_message 가 머지된 뒤 broadcast hook 이 `invalidateSelf` 호출하면
/// 자동 재조회로 카드가 갱신됨.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/auth_service.dart';
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
///
/// 본인 = idolId면 자동 통과 (F-024 아이돌 본인 채팅방 진입). 자기 응원 subscription은
/// 정책상 불가능하므로(subscription service가 자기 응원 차단) 별도 분기 필요.
@riverpod
Future<bool> isActiveSubscription(Ref ref, String idolId) {
  final myId = ref.watch(supabaseProvider).auth.currentUser?.id;
  if (myId != null && myId == idolId) return Future.value(true);
  return ref.watch(chatRoomRepositoryProvider).isActiveSubscription(idolId);
}

/// AppBar 용 아이돌 헤더 — 채팅방 화면 진입 시 1회 fetch.
@riverpod
Future<IdolHeader?> idolHeader(Ref ref, String idolId) {
  return ref.watch(chatRoomRepositoryProvider).fetchIdolHeader(idolId);
}
