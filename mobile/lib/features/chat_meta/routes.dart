/// F-021 / F-023 chat_meta — 라우트.
///
/// - `/chat/:idolId/replies/:messageId` — 아이돌 본인 broadcast의 fan_to_idol 답장 모아 보기.
/// 그 외 (markRead, reply composer)는 모달/silent — 라우트 없음.
library;

import 'package:go_router/go_router.dart';

import 'presentation/replies_screen.dart';

final List<RouteBase> chatMetaRoutes = <RouteBase>[
  GoRoute(
    path: '/chat/:idolId/replies/:messageId',
    builder: (context, state) => RepliesScreen(
      idolId: state.pathParameters['idolId']!,
      parentMessageId: state.pathParameters['messageId']!,
    ),
  ),
];
