/// F-034 후속 — 약관 재동의 자동 띄움 wrapper.
///
/// `main.dart`의 _GihagochiApp builder에서 child를 본 위젯으로 감싸면,
/// `/auth/me`의 `needsReagree`가 변할 때 자동으로 [ReagreeDialog] push.
///
/// PopScope로 dismiss 차단 → 동의 완료 또는 로그아웃만 출구.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_controller.dart';
import '../domain/auth_models.dart';
import 'reagree_dialog.dart';

class ReagreeGate extends ConsumerStatefulWidget {
  const ReagreeGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ReagreeGate> createState() => _ReagreeGateState();
}

class _ReagreeGateState extends ConsumerState<ReagreeGate> {
  bool _dialogShown = false;

  @override
  Widget build(BuildContext context) {
    // me 상태 변화 listen — needsReagree가 비어있지 않을 때만 1회 모달 push.
    ref.listen(authControllerProvider, (_, next) {
      final list = next.value?.needsReagree ?? const <AgreementType>[];
      if (list.isNotEmpty && !_dialogShown) {
        _dialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute<void>(
              fullscreenDialog: true,
              builder: (_) => ReagreeDialog(needsReagree: list),
            ),
          );
          if (mounted) _dialogShown = false;
        });
      }
    });

    return widget.child;
  }
}
