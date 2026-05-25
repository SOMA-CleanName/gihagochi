/// F-031 — 단일 토글 row.
///
/// optimistic UI: 사용자 탭 즉시 시각적 토글 → await patch → 실패 시 원복 + SnackBar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/notification_prefs_controller.dart';
import '../../domain/notification_models.dart';

class PrefToggleTile extends ConsumerStatefulWidget {
  const PrefToggleTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.buildPatch,
  });

  final String title;
  final String subtitle;
  final bool value;

  /// 새 값을 patch 객체로 변환. 각 토글마다 어느 필드를 PATCH 할지 결정.
  final NotificationPrefsPatch Function(bool newValue) buildPatch;

  @override
  ConsumerState<PrefToggleTile> createState() => _PrefToggleTileState();
}

class _PrefToggleTileState extends ConsumerState<PrefToggleTile> {
  bool _isUpdating = false;
  bool? _optimisticValue;

  Future<void> _onChanged(bool newValue) async {
    if (_isUpdating) return;
    setState(() {
      _isUpdating = true;
      _optimisticValue = newValue;
    });
    try {
      await ref
          .read(notificationPrefsControllerProvider.notifier)
          .patch(widget.buildPatch(newValue));
      // 성공 — controller state 갱신됨, optimistic 해제하면 watch한 widget.value가 새 값.
      if (mounted) {
        setState(() {
          _isUpdating = false;
          _optimisticValue = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUpdating = false;
        _optimisticValue = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('설정 변경 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = _optimisticValue ?? widget.value;
    return SwitchListTile(
      title: Text(widget.title),
      subtitle: Text(widget.subtitle),
      value: displayValue,
      onChanged: _isUpdating ? null : _onChanged,
    );
  }
}
