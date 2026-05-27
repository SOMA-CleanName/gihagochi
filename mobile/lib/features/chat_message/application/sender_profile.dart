/// 메시지 sender의 표시 정보 (닉네임 + 아바타).
///
/// chat_message message_list가 상대 메시지 좌측에 아바타 + 닉네임 표시할 때 사용.
/// 캐싱은 Riverpod autoDispose family — 같은 senderId는 화면 머무는 동안 재사용.
///
/// 아바타 우선순위:
/// - sender가 채팅방 owner(idolId)이면 idol_profiles.thumbnail_url (Storage path)
/// - 그 외 (팬) profiles.avatar_url
/// 둘 다 없으면 displayName 이니셜 fallback (Avatar 위젯 처리).
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/auth_service.dart';

part 'sender_profile.g.dart';

class SenderProfile {
  const SenderProfile({
    required this.id,
    required this.displayName,
    this.avatarPath,
    this.isIdol = false,
  });

  final String id;
  final String displayName;

  /// Storage path 또는 절대 URL. UI 측에서 signed URL 발급 필요 시 처리.
  final String? avatarPath;
  final bool isIdol;
}

@riverpod
Future<SenderProfile> senderProfile(
  Ref ref, {
  required String senderId,
  required String idolId,
}) async {
  final supabase = ref.watch(supabaseProvider);
  // 1. profile(display_name, avatar_url, role)
  final profile = await supabase
      .from('profiles')
      .select('display_name, avatar_url, role')
      .eq('id', senderId)
      .maybeSingle();
  final displayName = (profile?['display_name'] as String?) ?? '알 수 없음';
  String? avatarPath = profile?['avatar_url'] as String?;
  final isIdol = senderId == idolId;

  // 2. sender가 채팅방 idol이면 idol_profiles.thumbnail_url 우선
  if (isIdol) {
    final idolRow = await supabase
        .from('idol_profiles')
        .select('thumbnail_url')
        .eq('id', senderId)
        .maybeSingle();
    final thumbnail = idolRow?['thumbnail_url'] as String?;
    if (thumbnail != null && thumbnail.isNotEmpty) avatarPath = thumbnail;
  }

  return SenderProfile(
    id: senderId,
    displayName: displayName,
    avatarPath: avatarPath,
    isIdol: isIdol,
  );
}
