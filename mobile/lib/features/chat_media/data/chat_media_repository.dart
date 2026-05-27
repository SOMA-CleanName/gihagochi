/// F-019 / F-020 chat_media — Supabase Storage + messages 직결 (backend 0).
///
/// - `getSignedMediaUrl`: Storage path → signed URL (TTL 1h)
/// - `pickAndSendPhoto`: 갤러리/카메라 → 다운스케일(JPEG) → 업로드 → messages INSERT
/// - `sendVoiceMessage`: 로컬 m4a 경로 → 업로드 → messages INSERT
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/error/app_error.dart';
import '../../chat_message/application/uuid.dart';
import '../../chat_message/domain/message.dart';

part 'chat_media_repository.g.dart';

/// Storage 버킷명 — Supabase Dashboard에서 동일 이름으로 생성되어 있어야 함.
/// 사진/음성은 별도 버킷 (Dashboard 운영자 결정 — MIME/사이즈 제한 분리 관리).
const String chatPhotoBucket = 'chat-photo';
const String chatVoiceBucket = 'chat-voice';

/// 사진 다운스케일 최대 장변(px).
const int photoMaxSide = 2048;

/// JPEG 품질 (0~100). 다운스케일 후에도 5MB 초과 가능성 줄임.
const int photoJpegQuality = 85;

/// signed URL 기본 TTL (초).
const int signedUrlTtlSeconds = 3600;

@riverpod
ChatMediaRepository chatMediaRepository(Ref ref) {
  return ChatMediaRepository(supabase: ref.watch(supabaseProvider));
}

class ChatMediaRepository {
  ChatMediaRepository({required this.supabase, ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final SupabaseClient supabase;
  final ImagePicker _picker;

  String get _userId {
    final id = supabase.auth.currentUser?.id;
    if (id == null) {
      throw const UnauthorizedError(message: '로그인이 필요합니다.');
    }
    return id;
  }

  // ── 다운로드 ─────────────────────────────────

  /// Storage path → signed URL. 만료 시 호출자가 다시 호출.
  /// 호출자가 mediaType을 알아야 버킷 결정 가능 (photo/voice 분리 버킷).
  Future<String> getSignedMediaUrl(
    String storagePath, {
    required MediaType mediaType,
    int expiresInSeconds = signedUrlTtlSeconds,
  }) async {
    final bucket = _bucketFor(mediaType);
    try {
      return await supabase.storage
          .from(bucket)
          .createSignedUrl(storagePath, expiresInSeconds);
    } on StorageException catch (e) {
      throw ValidationError(
        message: '미디어 URL을 가져오지 못했습니다. (${e.message})',
        cause: e,
      );
    }
  }

  String _bucketFor(MediaType t) => switch (t) {
        MediaType.photo => chatPhotoBucket,
        MediaType.voice => chatVoiceBucket,
        MediaType.text => throw ArgumentError('text 메시지는 Storage 사용 안 함'),
      };

  // ── 사진 송신 (F-019) ────────────────────────

  /// 1. ImagePicker로 1장 선택 (사용자 취소 시 null)
  /// 2. 다운스케일 + JPEG 변환 (장변 2048px)
  /// 3. Storage PUT (`{idolId}/{messageId}.jpg`)
  /// 4. messages INSERT (역할별 type/recipient 분기)
  Future<Message?> pickAndSendPhoto({
    required String idolId,
    required ImageSource source,
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 100, // 다운스케일은 직접
    );
    if (picked == null) return null;

    final compressed = await _compressJpeg(picked.path);

    final messageId = generateUuidV4();
    final storagePath = '$idolId/$messageId.jpg';

    try {
      await supabase.storage.from(chatPhotoBucket).uploadBinary(
            storagePath,
            compressed,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );
    } on StorageException catch (e) {
      throw ValidationError(
        message: '사진 업로드에 실패했습니다. (${e.message})',
        cause: e,
      );
    }

    try {
      return await _insertMediaMessage(
        idolId: idolId,
        messageId: messageId,
        clientMessageId: messageId, // 동일하게 사용 (멱등성 단일 키)
        mediaType: MediaType.photo,
        storagePath: storagePath,
      );
    } catch (e) {
      // best-effort cleanup — RLS 거부로 INSERT 실패한 경우 객체 남으면 고아.
      unawaited(
        supabase.storage
            .from(chatPhotoBucket)
            .remove([storagePath])
            .catchError((_) => <FileObject>[]),
      );
      rethrow;
    }
  }

  // ── 음성 송신 (F-020) ────────────────────────

  /// 이미 녹음된 로컬 m4a 파일을 업로드 후 messages INSERT.
  /// 녹음(hold-to-record) UI는 VoiceRecorderButton 담당.
  Future<Message> sendVoiceMessage({
    required String idolId,
    required String localFilePath,
  }) async {
    final file = File(localFilePath);
    if (!file.existsSync()) {
      throw const ValidationError(message: '녹음 파일을 찾을 수 없습니다.');
    }
    final bytes = await file.readAsBytes();

    final messageId = generateUuidV4();
    final storagePath = '$idolId/$messageId.m4a';

    try {
      await supabase.storage.from(chatVoiceBucket).uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'audio/mp4',
              upsert: false,
            ),
          );
    } on StorageException catch (e) {
      throw ValidationError(
        message: '음성 업로드에 실패했습니다. (${e.message})',
        cause: e,
      );
    }

    try {
      return await _insertMediaMessage(
        idolId: idolId,
        messageId: messageId,
        clientMessageId: messageId,
        mediaType: MediaType.voice,
        storagePath: storagePath,
      );
    } catch (e) {
      unawaited(
        supabase.storage
            .from(chatVoiceBucket)
            .remove([storagePath])
            .catchError((_) => <FileObject>[]),
      );
      rethrow;
    }
  }

  // ── 내부 helper ──────────────────────────────

  Future<Uint8List> _compressJpeg(String sourcePath) async {
    final result = await FlutterImageCompress.compressWithFile(
      sourcePath,
      minWidth: photoMaxSide,
      minHeight: photoMaxSide,
      quality: photoJpegQuality,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
    if (result == null) {
      throw const ValidationError(message: '사진 처리에 실패했습니다.');
    }
    return result;
  }

  /// 역할별 type 분기 + INSERT. 본인 == idolId이면 idol_to_fans broadcast,
  /// 아니면 fan_to_idol. RLS가 최종 검증.
  Future<Message> _insertMediaMessage({
    required String idolId,
    required String messageId,
    required String clientMessageId,
    required MediaType mediaType,
    required String storagePath,
  }) async {
    final userId = _userId;
    final isIdolSelf = userId == idolId;

    final payload = <String, dynamic>{
      'id': messageId,
      'client_message_id': clientMessageId,
      'type': isIdolSelf ? 'idol_to_fans' : 'fan_to_idol',
      'sender_id': userId,
      'idol_id': idolId,
      // fan_to_idol → recipient = idol. idol_to_fans → NULL.
      if (!isIdolSelf) 'recipient_id': idolId,
      'media_type': _mediaTypeToDbValue(mediaType),
      'media_url': storagePath,
      // content NULL (CHECK: photo|voice → media_url NOT NULL, content unused)
    };

    try {
      final row = await supabase
          .from('messages')
          .insert(payload)
          .select()
          .single();
      return Message.fromJson(row);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw ValidationError(
          message: '이미 전송된 메시지입니다.',
          cause: e,
        );
      }
      throw ValidationError(
        message: '메시지 저장에 실패했습니다. (${e.message})',
        cause: e,
      );
    }
  }

  String _mediaTypeToDbValue(MediaType t) => switch (t) {
        MediaType.text => 'text',
        MediaType.photo => 'photo',
        MediaType.voice => 'voice',
      };
}
