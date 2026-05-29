/// F-001/F-002 약관 동의 화면. tos/privacy 필수, marketing 선택.
///
/// 동의 통과 시 → 가입 흐름은 OAuth + display_name 입력 화면으로.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_button.dart';
import '../application/signup_controller.dart';
import '../data/auth_repository.dart';

class SignupTermsScreen extends ConsumerStatefulWidget {
  const SignupTermsScreen({super.key});

  @override
  ConsumerState<SignupTermsScreen> createState() => _SignupTermsScreenState();
}

class _SignupTermsScreenState extends ConsumerState<SignupTermsScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _next() async {
    final draft = ref.read(signupDraftControllerProvider);
    if (!draft.tosAgreed || !draft.privacyAgreed) {
      setState(() => _error = '서비스 이용약관과 개인정보 처리방침에 동의해야 진행할 수 있어요.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // OAuth 먼저 — 끝나면 onAuthStateChange가 redirect를 트리거하고
      // 라우터가 /auth/signup/profile로 보냄(프로필 미존재).
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } catch (e, st) {
      debugPrint('[auth.google] signup_terms: signInWithOAuth 실패: $e\n$st');
      if (mounted) {
        setState(
          () => _error = '구글 로그인을 시작할 수 없어요. 잠시 후 다시 시도해주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(signupDraftControllerProvider);
    final notifier = ref.read(signupDraftControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('약관 동의')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CheckboxListTile(
                title: const Text('[필수] 서비스 이용약관'),
                value: draft.tosAgreed,
                onChanged: (v) => notifier.setTos(v ?? false),
              ),
              CheckboxListTile(
                title: const Text('[필수] 개인정보 처리방침'),
                value: draft.privacyAgreed,
                onChanged: (v) => notifier.setPrivacy(v ?? false),
              ),
              CheckboxListTile(
                title: const Text('[선택] 마케팅 수신'),
                value: draft.marketingAgreed,
                onChanged: (v) => notifier.setMarketing(v ?? false),
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
                label: 'Google로 가입 계속',
                onPressed:
                    _busy || !draft.tosAgreed || !draft.privacyAgreed
                        ? null
                        : _next,
                isLoading: _busy,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _busy ? null : () => context.go('/auth/landing'),
                child: const Text('취소'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
