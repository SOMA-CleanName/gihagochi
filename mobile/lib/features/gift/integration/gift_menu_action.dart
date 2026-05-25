/// F-027 — chat_room의 `chatRoomMenuActionsProvider`에 끼울 액션 helper.
///
/// chat_room의 공개 DTO `ChatRoomMenuAction`을 사용 (chat_room SPEC.md 공개 인터페이스).
/// main.dart에서 `chatRoomMenuActionsProvider.overrideWith((ref) => [giftMenuAction()])`.
library;

import 'package:flutter/material.dart';

import '../../chat_room/domain/chat_room_models.dart';
import '../presentation/gift_coming_soon_sheet.dart';

/// 채팅방 메뉴(롱프레스/⋮)에 표시될 "선물하기" 액션.
ChatRoomMenuAction giftMenuAction() {
  return ChatRoomMenuAction(
    icon: Icons.card_giftcard,
    label: '선물하기',
    onTap: (context, idolId) {
      showGiftComingSoonSheet(context, idolId: idolId);
    },
  );
}
