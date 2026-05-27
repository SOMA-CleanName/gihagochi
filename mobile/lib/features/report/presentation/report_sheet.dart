/// F-033 — 신고 BottomSheet.
///
/// chat_message가 메시지 롱프레스/메뉴에서 [showReportSheet] 호출.
/// reason 10~500자, 백엔드 PCR/409/400/404 케이스 처리.
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/report_repository.dart';

/// 진입 측 공개 함수. 메시지 ID 받아 BottomSheet 노출.
Future<void> showReportSheet(
  BuildContext context, {
  required String messageId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: SafeArea(
        child: _ReportSheetBody(messageId: messageId),
      ),
    ),
  );
}

class _ReportSheetBody extends ConsumerStatefulWidget {
  const _ReportSheetBody({required this.messageId});

  final String messageId;

  @override
  ConsumerState<_ReportSheetBody> createState() => _ReportSheetBodyState();
}

class _ReportSheetBodyState extends ConsumerState<_ReportSheetBody> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  static const _minLen = 10;
  static const _maxLen = 500;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _controller.text.trim();
    if (reason.length < _minLen || reason.length > _maxLen) return;
    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(reportRepositoryProvider);
      await repo.createReport(messageId: widget.messageId, reason: reason);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('신고가 접수되었습니다.')),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final msg = _mapErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      // 409(중복) / 404(없는 메시지)는 모달 닫기 — 재시도 의미 X.
      final status = e.response?.statusCode;
      if (status == 409 || status == 404) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('신고 전송 실패: $e')),
      );
    }
  }

  String _mapErrorMessage(DioException e) {
    return switch (e.response?.statusCode) {
      409 => '이미 신고한 메시지입니다.',
      400 => '본인이 보낸 메시지는 신고할 수 없습니다.',
      404 => '메시지를 찾을 수 없습니다.',
      _ => '신고 전송 실패: ${e.message ?? '알 수 없는 오류'}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final len = _controller.text.trim().length;
    final canSubmit = len >= _minLen && len <= _maxLen && !_isSubmitting;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              Text('메시지 신고', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '부적절한 내용을 신고해 주세요. 관리자가 확인 후 처리합니다.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            minLines: 4,
            maxLines: 6,
            maxLength: _maxLen,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '구체적인 이유를 적어 주세요 (최소 $_minLen자)',
              border: const OutlineInputBorder(),
              counterText: '$len / $_maxLen',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: canSubmit ? _submit : null,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('신고하기'),
          ),
        ],
      ),
    );
  }
}
