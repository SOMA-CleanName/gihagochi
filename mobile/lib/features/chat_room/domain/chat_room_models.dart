/// F-014 / F-016 — chat_room 도메인 모델.
///
/// ChatRoomCard = `/main`에 표시되는 채팅방 미리보기 카드 1장.
/// subscriptions + idol_profiles + 최근 메시지 1개를 조합한 view-model.
//
// freezed 3 + redirected constructor에 @JsonKey 붙이면 invalid_annotation_target
// 경고가 뜨지만 generator는 정상 처리.
// ignore_for_file: invalid_annotation_target
library;

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_room_models.freezed.dart';

/// 채팅방 카드 1장 — repository에서 조립되는 view-model.
///
/// JSON 직렬화 없음 — Supabase 직결에서 코드로 조립하므로 fromJson 불필요.
@freezed
abstract class ChatRoomCard with _$ChatRoomCard {
  const factory ChatRoomCard({
    required String idolId,
    required String stageName,
    String? thumbnailUrl,
    String? previewText,
    required DateTime previewTime,
    required bool idolSuspended,
  }) = _ChatRoomCard;
}

/// 채팅방 진입 시 AppBar에 표시할 아이돌 요약.
@freezed
abstract class IdolHeader with _$IdolHeader {
  const factory IdolHeader({
    required String idolId,
    required String stageName,
    String? thumbnailUrl,
    required bool suspended,
  }) = _IdolHeader;
}

/// 채팅방 메뉴 (롱프레스 / AppBar ⋮) 액션 1건.
///
/// 다른 피처 (subscription / report / notification) 가 자기 액션을 만들어서
/// `chatRoomMenuActionsProvider` 를 override 또는 합성으로 끼움.
///
/// freezed 안 씀 — IconData / function ref 가 JSON / 깊은 비교에 부적합.
@immutable
class ChatRoomMenuAction {
  const ChatRoomMenuAction({
    required this.icon,
    required this.label,
    this.destructive = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;

  /// `true` 면 빨간색 강조 (응원 취소 / 신고 등 되돌릴 수 없는 액션).
  final bool destructive;

  /// `idolId` 는 호출 시 컨텍스트 — 화면 측에서 BottomSheet 닫고 호출.
  final void Function(BuildContext context, String idolId) onTap;
}
