/// 채팅방 본문 + 메뉴 슬롯 Provider 3개.
///
/// 다른 피처가 머지될 때 `ProviderScope.overrides` 로 갈아끼움 (또는 액션 리스트에 추가).
/// chat_room 은 다른 피처를 모름 — 의존 단방향.
library;

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/chat_room_models.dart';
import '../presentation/widgets/slot_placeholders.dart';

part 'slot_providers.g.dart';

/// 채팅방 메시지 영역 — chat_message 머지 시 override.
/// family 의 키 = `idolId` (채팅방 식별자).
@riverpod
Widget chatMessageListSlot(Ref ref, String idolId) =>
    PlaceholderMessageList(idolId: idolId);

/// 채팅방 입력창 — chat_message 머지 시 override.
@riverpod
Widget chatMessageInputSlot(Ref ref, String idolId) =>
    PlaceholderMessageInput(idolId: idolId);

/// 채팅방 상단 2.5D AI 캐릭터 영역 — character 슬라이스 머지 시 override.
/// default = placeholder. 위치는 ChatRoomScreen이 `SizedBox(height: 화면*0.4)`로 결정.
@riverpod
Widget chatRoomCharacterSlot(Ref ref, String idolId) =>
    PlaceholderCharacter(idolId: idolId);

/// 채팅방 메뉴 (롱프레스 / AppBar ⋮) 액션 리스트.
///
/// subscription / report / notification 이 머지될 때 자기 액션을 add해서
/// 전체 리스트를 override.
///
/// default = `[]` — UI 가 빈 리스트일 때 "메뉴 준비 중" 표시.
@riverpod
List<ChatRoomMenuAction> chatRoomMenuActions(Ref ref) => const [];
