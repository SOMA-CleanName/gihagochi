/// 다른 피처가 끼울 수 있는 슬롯 Provider 3개.
///
/// chat_room / subscription / notification이 머지될 때 `ProviderScope`의
/// `overrides`로 본 Provider를 갈아끼움. profile은 그 피처들을 모름.
///
/// 사용 예 (다른 피처 머지 시 main.dart):
///   ProviderScope(
///     overrides: [
///       chatListSlotProvider.overrideWithValue(const ChatRoomList()),
///     ],
///     child: MyApp(),
///   )
library;

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../presentation/widgets/slot_defaults.dart';

part 'slot_providers.g.dart';

/// MainScreen 채팅방 리스트 슬롯. chat_room 머지 시 override.
@riverpod
Widget chatListSlot(Ref ref) => const EmptyChatListSlot();

/// 마이페이지 "응원 중인 아이돌" 슬롯. subscription 머지 시 override.
@riverpod
Widget subscriptionListSlot(Ref ref) => const PlaceholderSubscriptionSlot();

/// 마이페이지 "알림 설정" 슬롯. notification 머지 시 override.
@riverpod
Widget notificationSettingsSlot(Ref ref) => const PlaceholderNotificationSlot();
