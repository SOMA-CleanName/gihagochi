/// F-007(data) / F-014 / F-016 — chat_room 데이터 레이어.
///
/// 전부 Supabase 직결 + RLS. 백엔드 API 없음.
/// thumbnail은 path 저장 → signed URL 변환 (profile_repository와 동일 패턴).
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/error/app_error.dart';
import '../domain/chat_room_models.dart';

part 'chat_room_repository.g.dart';

const _thumbnailBucket = 'idol-thumbnails';
const _signedUrlTtlSeconds = 3600;

@riverpod
ChatRoomRepository chatRoomRepository(Ref ref) {
  return ChatRoomRepository(supabase: ref.watch(supabaseProvider));
}

class ChatRoomRepository {
  ChatRoomRepository({required this.supabase});

  final SupabaseClient supabase;

  String get _userId {
    final id = supabase.auth.currentUser?.id;
    if (id == null) {
      throw const UnauthorizedError(message: '로그인이 필요합니다.');
    }
    return id;
  }

  // ── 채널 리스트 (F-007/014) ────────────────

  /// 활성 응원 1건당 카드 1장. 최근 메시지 시간 DESC 정렬.
  Future<List<ChatRoomCard>> fetchChannelList() async {
    final userId = _userId;
    final subRows = await supabase
        .from('subscriptions')
        .select('idol_id, subscribed_at')
        .eq('fan_id', userId)
        .isFilter('unsubscribed_at', null);

    if (subRows.isEmpty) return const [];

    final cards = await Future.wait(
      subRows.map((r) => _buildCard(
            idolId: r['idol_id'] as String,
            subscribedAt: DateTime.parse(r['subscribed_at'] as String),
          )),
    );

    cards.sort((a, b) => b.previewTime.compareTo(a.previewTime));
    return cards;
  }

  Future<ChatRoomCard> _buildCard({
    required String idolId,
    required DateTime subscribedAt,
  }) async {
    // 병렬 fetch — idol_profiles / profiles.status / 최근 메시지.
    final results = await Future.wait([
      supabase
          .from('idol_profiles')
          .select('stage_name, thumbnail_url')
          .eq('id', idolId)
          .maybeSingle(),
      supabase
          .from('profiles')
          .select('status')
          .eq('id', idolId)
          .maybeSingle(),
      supabase
          .from('messages')
          .select('content, media_type, created_at')
          .eq('idol_id', idolId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle(),
    ]);

    final idolProfile = results[0];
    final profile = results[1];
    final latestMsg = results[2];

    final stageName = (idolProfile?['stage_name'] as String?) ?? '알 수 없는 아이돌';
    final thumbnailUrl = await _resolveThumbnailUrl(
      idolProfile?['thumbnail_url'] as String?,
    );
    final suspended = (profile?['status'] as String?) == 'suspended';

    String? previewText;
    var previewTime = subscribedAt;
    if (latestMsg != null) {
      previewText = _formatPreview(
        mediaType: latestMsg['media_type'] as String?,
        content: latestMsg['content'] as String?,
      );
      previewTime = DateTime.parse(latestMsg['created_at'] as String);
    }

    return ChatRoomCard(
      idolId: idolId,
      stageName: stageName,
      thumbnailUrl: thumbnailUrl,
      previewText: previewText,
      previewTime: previewTime,
      idolSuspended: suspended,
    );
  }

  String? _formatPreview({required String? mediaType, required String? content}) {
    switch (mediaType) {
      case 'photo':
        return '[사진]';
      case 'voice':
        return '[음성]';
      case 'text':
      default:
        return content?.replaceAll('\n', ' ').trim();
    }
  }

  // ── 채팅방 진입 (F-016) ────────────────────

  /// 진입 가능 여부 — 활성 subscription 1건이라도 있나.
  Future<bool> isActiveSubscription(String idolId) async {
    final userId = _userId;
    final row = await supabase
        .from('subscriptions')
        .select('idol_id')
        .eq('fan_id', userId)
        .eq('idol_id', idolId)
        .isFilter('unsubscribed_at', null)
        .maybeSingle();
    return row != null;
  }

  /// AppBar용 아이돌 요약.
  Future<IdolHeader?> fetchIdolHeader(String idolId) async {
    final results = await Future.wait([
      supabase
          .from('idol_profiles')
          .select('stage_name, thumbnail_url')
          .eq('id', idolId)
          .maybeSingle(),
      supabase
          .from('profiles')
          .select('status')
          .eq('id', idolId)
          .maybeSingle(),
    ]);

    final idolProfile = results[0];
    final profile = results[1];
    if (idolProfile == null) return null;

    final thumbnailUrl = await _resolveThumbnailUrl(
      idolProfile['thumbnail_url'] as String?,
    );
    return IdolHeader(
      idolId: idolId,
      stageName: idolProfile['stage_name'] as String,
      thumbnailUrl: thumbnailUrl,
      suspended: (profile?['status'] as String?) == 'suspended',
    );
  }

  // ── 내부 유틸 ──────────────────────────────

  Future<String?> _resolveThumbnailUrl(String? path) async {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    try {
      return await supabase.storage
          .from(_thumbnailBucket)
          .createSignedUrl(path, _signedUrlTtlSeconds);
    } on StorageException {
      return null;
    }
  }
}
