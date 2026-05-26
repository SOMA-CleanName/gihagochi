/// F-020 — 음성 녹음 마이크 버튼 (hold-to-record).
///
/// chat_message가 입력창에 배치. 누르고 있는 동안 녹음, 떼면 업로드.
/// 60초 초과 시 자동 stop.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

import '../data/chat_media_repository.dart';

const Duration kMaxVoiceDuration = Duration(seconds: 60);

class VoiceRecorderButton extends ConsumerStatefulWidget {
  const VoiceRecorderButton({super.key, required this.idolId});

  final String idolId;

  @override
  ConsumerState<VoiceRecorderButton> createState() =>
      _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends ConsumerState<VoiceRecorderButton> {
  final _recorder = AudioRecorder();
  bool _recording = false;
  bool _uploading = false;
  Timer? _autoStopTimer;

  @override
  void dispose() {
    _autoStopTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<String> _newRecordingPath() async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '${Directory.systemTemp.path}/voice_$ts.m4a';
  }

  Future<void> _start() async {
    if (_recording || _uploading) return;
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('마이크 권한이 필요합니다. 설정에서 허용해주세요.')),
      );
      return;
    }
    final path = await _newRecordingPath();
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );
    if (!mounted) return;
    setState(() => _recording = true);
    _autoStopTimer = Timer(kMaxVoiceDuration, () {
      if (_recording) unawaited(_stopAndSend(cancelled: false));
    });
  }

  Future<void> _stopAndSend({required bool cancelled}) async {
    if (!_recording) return;
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    final filePath = await _recorder.stop();
    setState(() => _recording = false);

    if (cancelled || filePath == null) {
      if (filePath != null) {
        unawaited(File(filePath).delete().catchError((_) => File(filePath)));
      }
      return;
    }

    setState(() => _uploading = true);
    if (!mounted) return;
    // mounted 시점에 capture — async gap 후엔 context 직접 사용 X.
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(chatMediaRepositoryProvider).sendVoiceMessage(
            idolId: widget.idolId,
            localFilePath: filePath,
          );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('음성을 보냈습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('음성 전송 실패: $e')),
      );
    } finally {
      unawaited(File(filePath).delete().catchError((_) => File(filePath)));
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = _uploading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(
            _recording ? Icons.fiber_manual_record : Icons.mic,
            color: _recording ? scheme.error : scheme.primary,
          );

    return GestureDetector(
      onLongPressStart: (_) => _start(),
      onLongPressEnd: (_) => _stopAndSend(cancelled: false),
      onLongPressCancel: () => _stopAndSend(cancelled: true),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _recording
              ? scheme.errorContainer
              : scheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: icon,
      ),
    );
  }
}
