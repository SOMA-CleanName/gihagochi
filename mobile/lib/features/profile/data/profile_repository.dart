/// F-007 / F-028 / F-030 / F-032 — profile 데이터 레이어.
///
/// 모두 Supabase 직결 (백엔드 API 없음). 권한은 RLS로 통제.
/// avatar / thumbnail은 Storage에 path 저장 → 표시할 때 signed URL 변환.
library;

import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/error/app_error.dart';
import '../domain/profile_models.dart';

part 'profile_repository.g.dart';

/// avatar 경로 규약: `<user_id>/avatar.jpg`
const _avatarBucket = 'avatars';

/// thumbnail 경로 규약: `<user_id>/thumbnail.jpg`
const _thumbnailBucket = 'idol-thumbnails';

/// signed URL 만료 (초). 1시간 — cached_network_image 캐시 효율과 권한 일관성 절충.
const _signedUrlTtlSeconds = 3600;

@riverpod
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepository(supabase: ref.watch(supabaseProvider));
}

class ProfileRepository {
  ProfileRepository({required this.supabase});

  final SupabaseClient supabase;

  String get _userId {
    final id = supabase.auth.currentUser?.id;
    if (id == null) {
      throw const UnauthorizedError(message: '로그인이 필요합니다.');
    }
    return id;
  }

  // ── 조회 ────────────────────────────────────

  /// 자기 profile + (role=idol일 때) idol_profiles join. avatar/thumbnail URL은
  /// path를 signed URL로 변환한 결과로 채움 (1시간 TTL).
  ///
  /// auth.users는 있는데 profiles row가 없는 케이스(가입 미완료/DB 리셋)는
  /// **자동 로그아웃** 후 NotFoundError를 던짐 — auth_guard가 /auth/landing으로 리다이렉트.
  /// 디드락 회피 (마이페이지가 안 뜨면 로그아웃 진입점도 없음).
  Future<MyProfile> fetchMyProfile() async {
    final userId = _userId;
    final Map<String, dynamic> profileRow;
    try {
      profileRow = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        await supabase.auth.signOut();
        throw const NotFoundError(message: '프로필이 없어 다시 로그인합니다.');
      }
      rethrow;
    }

    IdolDetail? idol;
    if (profileRow['role'] == 'idol') {
      final idolRow = await supabase
          .from('idol_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (idolRow != null) {
        final thumbnailUrl = await _resolveSignedUrl(
          bucket: _thumbnailBucket,
          path: idolRow['thumbnail_url'] as String?,
        );
        idol = IdolDetail.fromJson({
          ...idolRow,
          'thumbnail_url': thumbnailUrl,
        });
      }
    }

    final avatarUrl = await _resolveSignedUrl(
      bucket: _avatarBucket,
      path: profileRow['avatar_url'] as String?,
    );

    return MyProfile.fromJson({
      ...profileRow,
      'avatar_url': avatarUrl,
    }).copyWith(idol: idol);
  }

  // ── 텍스트 필드 업데이트 ────────────────────

  Future<void> updateFanProfile(FanProfileEdit input) async {
    final userId = _userId;
    await supabase.from('profiles').update({
      'display_name': input.displayName,
      'updated_at': _nowIso(),
    }).eq('id', userId);
  }

  Future<void> updateIdolProfile(IdolProfileEdit input) async {
    final userId = _userId;
    await supabase.from('profiles').update({
      'display_name': input.displayName,
      'updated_at': _nowIso(),
    }).eq('id', userId);

    try {
      await supabase.from('idol_profiles').update({
        'stage_name': input.stageName,
        'bio': input.bio,
        'updated_at': _nowIso(),
      }).eq('id', userId);
    } on PostgrestException catch (e) {
      // stage_name unique 위반 (23505) → 사용자에게 보여줄 메시지로 변환.
      if (e.code == '23505') {
        throw ValidationError(
          message: '이미 사용 중인 활동명입니다.',
          cause: e,
        );
      }
      rethrow;
    }
  }

  // ── Storage 업로드 + URL 컬럼 동기화 ────────

  /// avatar 업로드 + profiles.avatar_url에 path 저장. 다음 fetch 시 signed URL로 변환됨.
  Future<void> uploadAvatar(Uint8List bytes) async {
    final userId = _userId;
    final path = '$userId/avatar.jpg';
    await _uploadBinary(_avatarBucket, path, bytes);
    await supabase.from('profiles').update({
      'avatar_url': path,
      'updated_at': _nowIso(),
    }).eq('id', userId);
  }

  /// 아이돌 thumbnail 업로드 + idol_profiles.thumbnail_url 갱신.
  Future<void> uploadThumbnail(Uint8List bytes) async {
    final userId = _userId;
    final path = '$userId/thumbnail.jpg';
    await _uploadBinary(_thumbnailBucket, path, bytes);
    await supabase.from('idol_profiles').update({
      'thumbnail_url': path,
      'updated_at': _nowIso(),
    }).eq('id', userId);
  }

  // ── 회원 탈퇴 ──────────────────────────────

  /// soft delete — `profiles.deleted_at = NOW()` UPDATE.
  /// 호출자가 후속으로 Supabase signOut + 라우팅 처리.
  Future<void> softDeleteAccount() async {
    final userId = _userId;
    await supabase.from('profiles').update({
      'deleted_at': _nowIso(),
      'updated_at': _nowIso(),
    }).eq('id', userId);
  }

  // ── 내부 유틸 ──────────────────────────────

  Future<void> _uploadBinary(
    String bucket,
    String path,
    Uint8List bytes,
  ) async {
    try {
      await supabase.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );
    } on StorageException catch (e) {
      // 권한 거부 / 용량 초과 / MIME 거절 → 사용자 메시지로.
      throw ValidationError(
        message: '이미지 업로드에 실패했습니다. (${e.message})',
        cause: e,
      );
    }
  }

  Future<String?> _resolveSignedUrl({
    required String bucket,
    required String? path,
  }) async {
    if (path == null || path.isEmpty) return null;
    // 과거 데이터가 full URL로 저장돼 있을 수 있음 → 그대로 통과.
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    try {
      return await supabase.storage
          .from(bucket)
          .createSignedUrl(path, _signedUrlTtlSeconds);
    } on StorageException {
      // 객체 자체가 없으면 fallback은 null (이니셜 표시).
      return null;
    }
  }

  String _nowIso() => DateTime.now().toUtc().toIso8601String();
}
