/// F-033 report — 라우트 (없음, 모달만).
///
/// 본 슬라이스는 독립 화면 없음. 일관성 위해 빈 리스트 export.
/// 진입은 [showReportSheet] 공개 함수로 chat_message가 호출.
library;

import 'package:go_router/go_router.dart';

final List<RouteBase> reportRoutes = <RouteBase>[];
