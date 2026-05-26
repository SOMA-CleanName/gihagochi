// chat_media — Storage 상수 sanity (버킷명/TTL/사진 한도).
//
// SPEC.md "Storage 정책" + "비즈니스 룰" 과 코드 상수가 어긋나지 않는지 잠금.

import 'package:flutter_test/flutter_test.dart';

import 'package:gihagochi/features/chat_media/data/chat_media_repository.dart';

void main() {
  group('chat_media constants', () {
    test('버킷명은 SPEC과 동일', () {
      expect(chatMediaBucket, 'chat-media');
    });

    test('signed URL TTL = 1시간 (3600s)', () {
      expect(signedUrlTtlSeconds, 3600);
    });

    test('사진 다운스케일 장변 2048 / JPEG quality 85', () {
      expect(photoMaxSide, 2048);
      expect(photoJpegQuality, inInclusiveRange(70, 95));
    });
  });
}
