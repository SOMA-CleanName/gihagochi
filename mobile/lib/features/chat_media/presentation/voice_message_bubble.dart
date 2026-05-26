/// F-020 — 음성 메시지 인라인 재생 컨트롤.
///
/// chat_message의 _ConfirmedRow가 mediaType=voice 인 메시지에서 본 위젯 사용.
/// 1차 범위: 재생/일시정지 + 진행 바 + 길이. 캐릭터 모션 연계 X.
library;

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chat_media_repository.dart';

class VoiceMessageBubble extends ConsumerStatefulWidget {
  const VoiceMessageBubble({
    super.key,
    required this.storagePath,
    required this.isMine,
    required this.createdAt,
  });

  final String storagePath;
  final bool isMine;
  final DateTime createdAt;

  @override
  ConsumerState<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends ConsumerState<VoiceMessageBubble> {
  final _player = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _playing = false;
  bool _loading = false;
  String? _signedUrl;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<void>? _completeSub;

  @override
  void initState() {
    super.initState();
    _posSub = _player.onPositionChanged.listen((d) {
      if (mounted) setState(() => _position = d);
    });
    _durSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playing = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_loading) return;
    if (_playing) {
      await _player.pause();
      if (mounted) setState(() => _playing = false);
      return;
    }
    if (_signedUrl == null) {
      setState(() => _loading = true);
      try {
        _signedUrl = await ref
            .read(chatMediaRepositoryProvider)
            .getSignedMediaUrl(widget.storagePath);
      } catch (e) {
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('음성 로드 실패: $e')),
        );
        return;
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
    await _player.play(UrlSource(_signedUrl!));
    if (mounted) setState(() => _playing = true);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = widget.isMine ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = widget.isMine ? scheme.onPrimary : scheme.onSurface;
    final progress = _duration.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);

    return Align(
      alignment: widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              IconButton(
                icon: _loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: fg,
                        ),
                      )
                    : Icon(
                        _playing ? Icons.pause : Icons.play_arrow,
                        color: fg,
                      ),
                onPressed: _toggle,
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  color: fg,
                  backgroundColor: fg.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _duration.inMilliseconds > 0
                    ? _fmt(_position == Duration.zero ? _duration : _position)
                    : '–:––',
                style: TextStyle(color: fg, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
