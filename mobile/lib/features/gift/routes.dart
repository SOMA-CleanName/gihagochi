/// F-027 gift 라우트 — `/gift` 직접 접근 백업.
///
/// 주 진입은 chat_room이 `showGiftComingSoonSheet(context, idolId: ...)` 호출 (BottomSheet).
/// 본 라우트는 마이페이지 등 다른 경로에서 진입 시 fallback.
library;

import 'package:go_router/go_router.dart';

import 'presentation/gift_coming_soon_sheet.dart';

final List<RouteBase> giftRoutes = [
  GoRoute(
    path: '/gift',
    builder: (context, state) {
      final idolId = state.uri.queryParameters['idolId'];
      return GiftComingSoonScreen(idolId: idolId);
    },
  ),
];
