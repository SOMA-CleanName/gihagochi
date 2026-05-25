/// image_picker로 갤러리에서 이미지 선택 + 자체 리사이즈/포맷 검증.
///
/// 본 서비스는 bytes만 반환. 업로드는 호출자가 ProfileRepository로 처리.
library;

import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_error.dart';

part 'image_upload_service.g.dart';

/// 최대 파일 크기 (Storage 버킷 제한과 동일).
const _maxFileSizeBytes = 5 * 1024 * 1024;

/// 허용 확장자.
const _allowedExtensions = ['jpg', 'jpeg', 'png'];

@riverpod
ImageUploadService imageUploadService(Ref ref) => ImageUploadService();

class ImageUploadService {
  final ImagePicker _picker = ImagePicker();

  /// avatar용 — 512x512로 리사이즈.
  Future<Uint8List?> pickAvatar() => _pick(maxDim: 512);

  /// thumbnail용 — 1024x1024로 리사이즈.
  Future<Uint8List?> pickThumbnail() => _pick(maxDim: 1024);

  /// 사용자 취소 시 null. 검증 실패 시 ValidationError throw.
  Future<Uint8List?> _pick({required double maxDim}) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxDim,
      maxHeight: maxDim,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final ext = picked.path.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(ext)) {
      throw const ValidationError(
        message: 'JPEG / PNG 파일만 지원합니다.',
      );
    }

    final bytes = await picked.readAsBytes();
    if (bytes.length > _maxFileSizeBytes) {
      throw const ValidationError(
        message: '5MB 이하 이미지만 업로드 가능합니다.',
      );
    }
    return bytes;
  }
}
