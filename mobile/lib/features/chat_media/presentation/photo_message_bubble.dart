/// F-019 — 사진 메시지 버블 + 풀스크린 뷰어.
///
/// chat_message의 _ConfirmedRow가 mediaType=photo 인 메시지에서 본 위젯 사용.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chat_media_repository.dart';

class PhotoMessageBubble extends ConsumerWidget {
  const PhotoMessageBubble({
    super.key,
    required this.storagePath,
    required this.isMine,
    required this.createdAt,
  });

  final String storagePath;
  final bool isMine;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: GestureDetector(
          onTap: () => _openViewer(context, ref),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 220,
                maxHeight: 280,
              ),
              child: _SignedImage(storagePath: storagePath),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openViewer(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _PhotoViewerScreen(storagePath: storagePath),
      ),
    );
  }
}

class _SignedImage extends ConsumerWidget {
  const _SignedImage({required this.storagePath});

  final String storagePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String>(
      future: ref.read(chatMediaRepositoryProvider).getSignedMediaUrl(storagePath),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            width: 220,
            height: 220,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (snap.hasError || snap.data == null) {
          return Container(
            color: Theme.of(context).colorScheme.errorContainer,
            padding: const EdgeInsets.all(12),
            child: const Text('[사진 로드 실패]'),
          );
        }
        return CachedNetworkImage(
          imageUrl: snap.data!,
          fit: BoxFit.cover,
          placeholder: (_, __) => const SizedBox(
            width: 220,
            height: 220,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (_, __, ___) => const Padding(
            padding: EdgeInsets.all(12),
            child: Text('[사진 로드 실패]'),
          ),
        );
      },
    );
  }
}

class _PhotoViewerScreen extends ConsumerWidget {
  const _PhotoViewerScreen({required this.storagePath});

  final String storagePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: _SignedImage(storagePath: storagePath),
        ),
      ),
    );
  }
}
