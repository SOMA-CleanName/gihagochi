/// F-019 — 사진 선택 BottomSheet (갤러리 / 카메라).
///
/// chat_message가 입력창 카메라 버튼에서 [showPhotoPickerSheet] 호출.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/chat_media_repository.dart';

/// 진입 측 공개 함수. 사용자가 source 선택 → 송신 → 결과 SnackBar.
Future<void> showPhotoPickerSheet(
  BuildContext context, {
  required String idolId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: _PhotoPickerBody(idolId: idolId),
    ),
  );
}

class _PhotoPickerBody extends ConsumerWidget {
  const _PhotoPickerBody({required this.idolId});

  final String idolId;

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    Navigator.of(context).pop();
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('사진 업로드 중…'),
        duration: Duration(seconds: 30),
      ),
    );
    try {
      final result = await ref
          .read(chatMediaRepositoryProvider)
          .pickAndSendPhoto(idolId: idolId, source: source);
      messenger.hideCurrentSnackBar();
      if (result == null) return; // 사용자 취소
      messenger.showSnackBar(
        const SnackBar(content: Text('사진을 보냈습니다.')),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('사진 전송 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.photo_library),
          title: const Text('갤러리에서 선택'),
          onTap: () => _pick(context, ref, ImageSource.gallery),
        ),
        ListTile(
          leading: const Icon(Icons.camera_alt),
          title: const Text('카메라로 촬영'),
          onTap: () => _pick(context, ref, ImageSource.camera),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
