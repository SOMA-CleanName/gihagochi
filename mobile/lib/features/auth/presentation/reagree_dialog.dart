/// F-034 후속 — 약관 버전 변경 시 강제 재동의 fullscreen modal.
///
/// `/auth/me`의 `needsReagree`가 비어있지 않을 때 [ReagreeGate]가 자동 push.
/// 닫기 X (PopScope로 back 차단). 동의 완료 또는 "로그아웃"만 출구.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_button.dart';
import '../application/auth_controller.dart';
import '../data/auth_repository.dart';
import '../domain/auth_models.dart';

class ReagreeDialog extends ConsumerStatefulWidget {
  const ReagreeDialog({super.key, required this.needsReagree});

  /// 백엔드가 stale로 판정한 type들. tos/privacy는 무조건 체크 표시.
  final List<AgreementType> needsReagree;

  @override
  ConsumerState<ReagreeDialog> createState() => _ReagreeDialogState();
}

class _ReagreeDialogState extends ConsumerState<ReagreeDialog> {
  bool _tos = false;
  bool _privacy = false;
  bool _marketing = false;
  bool _busy = false;
  String? _error;

  bool get _showTos => widget.needsReagree.contains(AgreementType.tos);
  bool get _showPrivacy => widget.needsReagree.contains(AgreementType.privacy);
  bool get _showMarketing =>
      widget.needsReagree.contains(AgreementType.marketing);

  bool get _canSubmit =>
      (!_showTos || _tos) && (!_showPrivacy || _privacy) && !_busy;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      final terms = await repo.fetchCurrentTerms();
      await repo.reagree(
        ReagreeRequest(
          agreements: AgreementsInput(
            tos: AgreementInput(version: terms.tos, agreed: _tos),
            privacy: AgreementInput(version: terms.privacy, agreed: _privacy),
            marketing: _showMarketing
                ? AgreementInput(version: terms.marketing, agreed: _marketing)
                : null,
          ),
        ),
      );
      await ref.read(authControllerProvider.notifier).refresh();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _error = '동의 처리에 실패했어요. 잠시 후 다시 시도해주세요.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).signOut();
      await ref.read(authControllerProvider.notifier).refresh();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('약관 재동의 필요'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '서비스 약관이 업데이트됐어요.\n'
                  '계속 사용하려면 아래 항목에 다시 동의해주세요.',
                ),
                const SizedBox(height: 16),
                if (_showTos)
                  CheckboxListTile(
                    title: const Text('[필수] 서비스 이용약관 (개정)'),
                    value: _tos,
                    onChanged:
                        _busy ? null : (v) => setState(() => _tos = v ?? false),
                  ),
                if (_showPrivacy)
                  CheckboxListTile(
                    title: const Text('[필수] 개인정보 처리방침 (개정)'),
                    value: _privacy,
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => _privacy = v ?? false),
                  ),
                if (_showMarketing)
                  CheckboxListTile(
                    title: const Text('[선택] 마케팅 수신 (개정)'),
                    value: _marketing,
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => _marketing = v ?? false),
                  ),
                const Spacer(),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
                AppButton(
                  label: '동의하고 계속',
                  onPressed: _canSubmit ? _submit : null,
                  isLoading: _busy,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy ? null : _logout,
                  child: const Text('로그아웃'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
