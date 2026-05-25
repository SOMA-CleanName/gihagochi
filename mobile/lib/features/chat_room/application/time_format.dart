/// 채팅방 카드 시간 표기 — relative format.
///
/// 1분 미만 = "방금 전"
/// 1시간 미만 = "n분 전"
/// 24시간 미만 = "n시간 전"
/// 30일 미만 = "n일 전"
/// 그 이상 = "YYYY-MM-DD"
library;

import 'package:intl/intl.dart';

String formatChatRoomTime(DateTime time, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = reference.difference(time);

  if (diff.isNegative) return '방금 전';
  if (diff.inMinutes < 1) return '방금 전';
  if (diff.inHours < 1) return '${diff.inMinutes}분 전';
  if (diff.inDays < 1) return '${diff.inHours}시간 전';
  if (diff.inDays < 30) return '${diff.inDays}일 전';

  return DateFormat('yyyy-MM-dd').format(time.toLocal());
}
