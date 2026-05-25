/// F-016 — chat_room 라우트.
///
/// `/main` 의 채팅방 리스트는 routes 가 아니라 ProviderScope.overrides
/// 로 끼움 (`main.dart` 참고).
library;

import 'package:go_router/go_router.dart';

import 'presentation/chat_room_screen.dart';

final List<RouteBase> chatRoomRoutes = [
  GoRoute(
    path: '/chat/:idolId',
    builder: (context, state) => ChatRoomScreen(
      idolId: state.pathParameters['idolId']!,
    ),
  ),
];
